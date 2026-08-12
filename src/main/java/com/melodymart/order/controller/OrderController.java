package com.melodymart.order.controller;

import com.melodymart.auth.entity.User;
import com.melodymart.auth.entity.AuditLog;
import com.melodymart.auth.repository.UserRepository;
import com.melodymart.auth.repository.AuditLogRepository;
import com.melodymart.order.entity.Order;
import com.melodymart.order.entity.OrderItem;
import com.melodymart.order.entity.Payment;
import com.melodymart.order.entity.Notification;
import com.melodymart.order.entity.enums.OrderStatus;
import com.melodymart.order.entity.Address;
import com.melodymart.order.repository.AddressRepository;
import com.melodymart.order.repository.OrderRepository;
import com.melodymart.order.repository.PaymentRepository;
import com.melodymart.order.repository.NotificationRepository;
import com.melodymart.product.entity.Product;
import com.melodymart.product.entity.InventoryHistory;
import com.melodymart.product.repository.ProductRepository;
import com.melodymart.product.repository.InventoryHistoryRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api")
public class OrderController {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private PaymentRepository paymentRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private InventoryHistoryRepository inventoryHistoryRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    // --- CUSTOMER ORDERS ---

    @GetMapping("/orders/history")
    public ResponseEntity<?> getOrderHistory(HttpServletRequest request) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "User not logged in"));
        }
        List<Order> orders = orderRepository.findByUserUsername(username);
        return ResponseEntity.ok(orders);
    }

    @PostMapping("/orders/checkout")
    public ResponseEntity<?> checkoutOrder(HttpServletRequest request, @RequestBody Map<String, Object> payload) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "User not logged in"));
        }

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new NoSuchElementException("User not found"));

        // Resolve addresses
        Long shippingAddrId = Long.valueOf(payload.get("shippingAddressId").toString());
        Long billingAddrId = Long.valueOf(payload.get("billingAddressId").toString());

        Address shippingAddr = addressRepository.findById(shippingAddrId).orElse(null);
        if (shippingAddr == null) {
            List<Address> userAddrs = addressRepository.findByUser(user);
            if (!userAddrs.isEmpty()) {
                shippingAddr = userAddrs.get(0);
            } else {
                shippingAddr = new Address();
                shippingAddr.setUser(user);
                shippingAddr.setAddressLine1("123 Music Street");
                shippingAddr.setCity("Mumbai");
                shippingAddr.setState("MH");
                shippingAddr.setCountry("India");
                shippingAddr.setPostalCode("400001");
                shippingAddr.setAddressType(com.melodymart.order.entity.enums.AddressType.HOME);
                shippingAddr.setIsDefault(true);
                shippingAddr = addressRepository.save(shippingAddr);
            }
        }
        
        Address billingAddr = addressRepository.findById(billingAddrId).orElse(shippingAddr);

        Order order = new Order();
        order.setUser(user);
        order.setShippingAddress(shippingAddr);
        order.setBillingAddress(billingAddr);
        order.setOrderStatus(OrderStatus.PENDING);

        BigDecimal totalPrice = new BigDecimal(payload.get("totalPrice").toString());
        BigDecimal shippingCharge = new BigDecimal(payload.get("shippingCharge").toString());
        BigDecimal taxCharge = new BigDecimal(payload.get("taxCharge").toString());
        BigDecimal netAmount = new BigDecimal(payload.get("netAmount").toString());

        order.setTotalPrice(totalPrice);
        order.setShippingCharge(shippingCharge);
        order.setTaxCharge(taxCharge);
        order.setNetAmount(netAmount);
        order.setTrackingNumber("MM-" + System.currentTimeMillis());

        // Process items
        List<Map<String, Object>> itemsPayload = (List<Map<String, Object>>) payload.get("items");
        List<OrderItem> orderItems = new ArrayList<>();

        for (Map<String, Object> itemData : itemsPayload) {
            Long productId = Long.valueOf(itemData.get("productId").toString());
            int quantity = Integer.parseInt(itemData.get("quantity").toString());

            Product product = productRepository.findById(productId)
                    .orElseThrow(() -> new NoSuchElementException("Product not found"));

            if (product.getStockQuantity() < quantity) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Stock not available for product: " + product.getName()));
            }

            // Deduct stock
            int newStock = product.getStockQuantity() - quantity;
            product.setStockQuantity(newStock);
            productRepository.save(product);

            // Log inventory history
            inventoryHistoryRepository.save(new InventoryHistory(product, -quantity, newStock, "PURCHASE"));

            // Check low stock
            if (newStock == 0) {
                notificationRepository.save(new Notification("Product out of stock: " + product.getName(), "OUT_OF_STOCK"));
            } else if (newStock <= 5) {
                notificationRepository.save(new Notification("Product running low on stock (" + newStock + " left): " + product.getName(), "LOW_STOCK"));
            }

            OrderItem orderItem = new OrderItem();
            orderItem.setOrder(order);
            orderItem.setProduct(product);
            orderItem.setQuantity(quantity);
            orderItem.setPrice(product.getPrice());
            orderItems.add(orderItem);
        }

        order.setOrderItems(orderItems);

        // Process payment
        String paymentMethod = (String) payload.get("paymentMethod");
        Payment payment = new Payment();
        payment.setOrder(order);
        payment.setPaymentMethod(com.melodymart.order.entity.enums.PaymentMethod.valueOf(paymentMethod));
        payment.setPaymentStatus(com.melodymart.order.entity.enums.PaymentStatus.COMPLETED); // simplified checkout
        payment.setAmount(netAmount);
        payment.setTransactionId("TXN-" + System.currentTimeMillis());
        
        order.setPayments(Collections.singletonList(payment));

        order = orderRepository.save(order);

        // Notify new order
        notificationRepository.save(new Notification("New Order placed: " + order.getTrackingNumber() + " by " + user.getFullName() + " for amount $" + netAmount, "NEW_ORDER"));

        // Log user activity
        AuditLog auditLog = new AuditLog(user.getId(), user.getUsername(), "CHECKOUT", "Placed order: " + order.getTrackingNumber() + " for amount $" + netAmount, request.getRemoteAddr());
        auditLogRepository.save(auditLog);

        return ResponseEntity.ok(order);
    }

    // --- ADMIN ORDERS & NOTIFICATIONS ---

    @GetMapping("/admin/orders")
    public ResponseEntity<?> getAllOrders() {
        return ResponseEntity.ok(orderRepository.findAll());
    }

    @GetMapping("/admin/orders/{id}")
    public ResponseEntity<?> getOrderById(@PathVariable("id") Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + id));
        return ResponseEntity.ok(order);
    }

    @PutMapping("/admin/orders/{id}/status")
    public ResponseEntity<?> updateOrderStatus(@PathVariable("id") Long id, @RequestBody Map<String, String> payload) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + id));

        String statusStr = payload.get("status");
        OrderStatus status = OrderStatus.valueOf(statusStr);
        order.setOrderStatus(status);
        orderRepository.save(order);

        return ResponseEntity.ok(order);
    }

    @GetMapping("/admin/notifications")
    public ResponseEntity<?> getNotifications() {
        return ResponseEntity.ok(notificationRepository.findByIsReadFalseOrderByCreatedAtDesc());
    }

    @PostMapping("/admin/notifications/{id}/read")
    public ResponseEntity<?> markNotificationAsRead(@PathVariable("id") Long id) {
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Notification not found"));
        notification.setIsRead(true);
        notificationRepository.save(notification);
        return ResponseEntity.ok(Map.of("message", "Notification marked as read"));
    }
}
