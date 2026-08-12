package com.melodymart.product.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

/**
 * Entity mapping for the 'product_specifications' table.
 * Stores technical product properties as key-value pairs (e.g., Weight: 2.5 kg).
 */
@Entity
@Table(name = "product_specifications", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"product_id", "spec_key"}, name = "uk_product_specifications_key")
}, indexes = {
    @Index(name = "idx_product_specifications_product", columnList = "product_id")
})
public class ProductSpecification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull(message = "Product is required")
    @com.fasterxml.jackson.annotation.JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false, foreignKey = @ForeignKey(name = "fk_product_specifications_product"))
    private Product product;

    @NotBlank(message = "Specification key is required")
    @Size(max = 100, message = "Specification key must not exceed 100 characters")
    @Column(name = "spec_key", length = 100, nullable = false)
    private String specKey;

    @NotBlank(message = "Specification value is required")
    @Size(max = 255, message = "Specification value must not exceed 255 characters")
    @Column(name = "spec_value", length = 255, nullable = false)
    private String specValue;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Default constructor
    public ProductSpecification() {}

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
    }

    public String getSpecKey() {
        return specKey;
    }

    public void setSpecKey(String specKey) {
        this.specKey = specKey;
    }

    public String getSpecValue() {
        return specValue;
    }

    public void setSpecValue(String specValue) {
        this.specValue = specValue;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}
