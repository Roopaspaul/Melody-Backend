package com.melodymart.order.repository;

import com.melodymart.order.entity.Order;
import com.melodymart.order.entity.enums.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByUserUsername(String username);
    List<Order> findByOrderStatus(OrderStatus orderStatus);
    
    @Query("SELECT COUNT(o) FROM Order o WHERE o.orderStatus = :status")
    long countByOrderStatus(@Param("status") OrderStatus status);

    @Query("SELECT o FROM Order o WHERE o.createdAt >= :startDate")
    List<Order> findOrdersCreatedAfter(@Param("startDate") LocalDateTime startDate);

    List<Order> findByCreatedAtBetween(LocalDateTime start, LocalDateTime end);
}
