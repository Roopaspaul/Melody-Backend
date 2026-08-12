package com.melodymart.shopping.controller;

import com.melodymart.auth.entity.User;
import com.melodymart.auth.repository.UserRepository;
import com.melodymart.product.entity.Product;
import com.melodymart.product.repository.ProductRepository;
import com.melodymart.shopping.entity.Cart;
import com.melodymart.shopping.entity.CartItem;
import com.melodymart.shopping.entity.Wishlist;
import com.melodymart.shopping.repository.CartItemRepository;
import com.melodymart.shopping.repository.CartRepository;
import com.melodymart.shopping.repository.WishlistRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/shopping")
public class ShoppingController {

    @Autowired
    private CartRepository cartRepository;

    @Autowired
    private CartItemRepository cartItemRepository;

    @Autowired
    private WishlistRepository wishlistRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProductRepository productRepository;

    private Cart getOrCreateCart(User user) {
        return cartRepository.findByUserId(user.getId()).orElseGet(() -> {
            Cart cart = new Cart();
            cart.setUser(user);
            return cartRepository.save(cart);
        });
    }

    @GetMapping("/cart")
    public ResponseEntity<?> getCart(HttpServletRequest request) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Not logged in"));
        }
        User user = userRepository.findByUsername(username).orElseThrow();
        Cart cart = getOrCreateCart(user);
        
        List<Map<String, Object>> items = cart.getCartItems().stream().map(ci -> {
            Map<String, Object> map = new HashMap<>();
            map.put("productId", ci.getProduct().getId());
            map.put("quantity", ci.getQuantity());
            map.put("priceAtAdded", ci.getPriceAtAdded());
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(items);
    }

    @PostMapping("/cart")
    public ResponseEntity<?> addToCart(HttpServletRequest request, @RequestBody Map<String, Object> body) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Not logged in"));
        }
        User user = userRepository.findByUsername(username).orElseThrow();
        Long productId = Long.valueOf(body.get("productId").toString());
        Integer quantity = Integer.valueOf(body.get("quantity").toString());

        Product product = productRepository.findById(productId).orElseThrow();
        Cart cart = getOrCreateCart(user);

        Optional<CartItem> existingItemOpt = cart.getCartItems().stream()
                .filter(ci -> ci.getProduct().getId().equals(productId))
                .findFirst();

        if (existingItemOpt.isPresent()) {
            CartItem ci = existingItemOpt.get();
            ci.setQuantity(quantity);
            cartItemRepository.save(ci);
        } else {
            CartItem ci = new CartItem();
            ci.setCart(cart);
            ci.setProduct(product);
            ci.setQuantity(quantity);
            BigDecimal price = product.getPrice().multiply(BigDecimal.ONE.subtract(product.getDiscountPercentage().divide(BigDecimal.valueOf(100))));
            ci.setPriceAtAdded(price);
            cart.addCartItem(ci);
            cartRepository.save(cart);
        }

        return ResponseEntity.ok(Map.of("message", "Cart updated"));
    }

    @DeleteMapping("/cart/{productId}")
    public ResponseEntity<?> deleteCartItem(HttpServletRequest request, @PathVariable("productId") Long productId) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Not logged in"));
        }
        User user = userRepository.findByUsername(username).orElseThrow();
        Cart cart = getOrCreateCart(user);
        cartItemRepository.deleteByCartIdAndProductId(cart.getId(), productId);
        return ResponseEntity.ok(Map.of("message", "Item deleted"));
    }

    @DeleteMapping("/cart")
    public ResponseEntity<?> clearCart(HttpServletRequest request) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Not logged in"));
        }
        User user = userRepository.findByUsername(username).orElseThrow();
        Cart cart = getOrCreateCart(user);
        cart.getCartItems().clear();
        cartRepository.save(cart);
        return ResponseEntity.ok(Map.of("message", "Cart cleared"));
    }

    @GetMapping("/wishlist")
    public ResponseEntity<?> getWishlist(HttpServletRequest request) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Not logged in"));
        }
        User user = userRepository.findByUsername(username).orElseThrow();
        List<Wishlist> list = wishlistRepository.findByUserId(user.getId());
        List<Long> productIds = list.stream().map(w -> w.getProduct().getId()).collect(Collectors.toList());
        return ResponseEntity.ok(productIds);
    }

    @PostMapping("/wishlist/{productId}")
    public ResponseEntity<?> addToWishlist(HttpServletRequest request, @PathVariable("productId") Long productId) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Not logged in"));
        }
        User user = userRepository.findByUsername(username).orElseThrow();
        Product product = productRepository.findById(productId).orElseThrow();

        if (wishlistRepository.findByUserIdAndProductId(user.getId(), productId).isEmpty()) {
            Wishlist w = new Wishlist();
            w.setUser(user);
            w.setProduct(product);
            wishlistRepository.save(w);
        }

        return ResponseEntity.ok(Map.of("message", "Added to wishlist"));
    }

    @DeleteMapping("/wishlist/{productId}")
    public ResponseEntity<?> removeFromWishlist(HttpServletRequest request, @PathVariable("productId") Long productId) {
        String username = (String) request.getAttribute("username");
        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Not logged in"));
        }
        User user = userRepository.findByUsername(username).orElseThrow();
        wishlistRepository.deleteByUserIdAndProductId(user.getId(), productId);
        return ResponseEntity.ok(Map.of("message", "Removed from wishlist"));
    }
}
