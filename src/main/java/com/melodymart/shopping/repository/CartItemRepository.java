package com.melodymart.shopping.repository;

import com.melodymart.shopping.entity.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {
    @Transactional
    void deleteByCartIdAndProductId(Long cartId, Long productId);
}
