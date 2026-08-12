package com.melodymart.product.repository;

import com.melodymart.product.entity.SubCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface SubCategoryRepository extends JpaRepository<SubCategory, Long> {
    Optional<SubCategory> findBySlug(String slug);
    List<SubCategory> findByCategoryId(Long categoryId);
}
