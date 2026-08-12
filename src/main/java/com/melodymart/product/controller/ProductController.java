package com.melodymart.product.controller;

import com.melodymart.product.entity.Brand;
import com.melodymart.product.entity.Category;
import com.melodymart.product.entity.Product;
import com.melodymart.product.entity.SubCategory;
import com.melodymart.product.repository.BrandRepository;
import com.melodymart.product.repository.CategoryRepository;
import com.melodymart.product.repository.ProductRepository;
import com.melodymart.product.repository.SubCategoryRepository;
import com.melodymart.order.entity.Notification;
import com.melodymart.order.repository.NotificationRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public class ProductController {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private BrandRepository brandRepository;

    @Autowired
    private SubCategoryRepository subCategoryRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private com.fasterxml.jackson.databind.ObjectMapper objectMapper;

    // --- PRODUCTS SECTION ---
    
    @GetMapping("/products")
    public ResponseEntity<?> getAllProducts(
            @RequestParam(value = "search", required = false) String search,
            @RequestParam(value = "category", required = false) String categorySlug,
            @RequestParam(value = "brand", required = false) String brandSlug,
            @RequestParam(value = "minPrice", required = false) BigDecimal minPrice,
            @RequestParam(value = "maxPrice", required = false) BigDecimal maxPrice,
            @RequestParam(value = "minRating", required = false) BigDecimal minRating,
            @RequestParam(value = "inStock", required = false) Boolean inStock,
            @RequestParam(value = "sort", required = false) String sort,
            @RequestParam(value = "includeDeleted", required = false, defaultValue = "false") boolean includeDeleted) {

        List<Product> products = productRepository.findAll();

        // Filter
        products = products.stream()
                .filter(p -> (includeDeleted || !p.getIsDeleted()))
                .filter(p -> (search == null || search.trim().isEmpty() || 
                              p.getName().toLowerCase().contains(search.toLowerCase()) ||
                              p.getSku().toLowerCase().contains(search.toLowerCase()) ||
                              (p.getDescription() != null && p.getDescription().toLowerCase().contains(search.toLowerCase()))))
                .filter(p -> (categorySlug == null || p.getCategory().getSlug().equalsIgnoreCase(categorySlug)))
                .filter(p -> (brandSlug == null || p.getBrand().getSlug().equalsIgnoreCase(brandSlug)))
                .filter(p -> (minPrice == null || p.getPrice().compareTo(minPrice) >= 0))
                .filter(p -> (maxPrice == null || p.getPrice().compareTo(maxPrice) <= 0))
                .filter(p -> (minRating == null || p.getRating().compareTo(minRating) >= 0))
                .filter(p -> (inStock == null || !inStock || p.getStockQuantity() > 0))
                .collect(Collectors.toList());

        // Sort
        if (sort != null) {
            switch (sort.toLowerCase()) {
                case "price-asc":
                    products.sort(Comparator.comparing(Product::getPrice));
                    break;
                case "price-desc":
                    products.sort(Comparator.comparing(Product::getPrice).reversed());
                    break;
                case "oldest":
                    products.sort(Comparator.comparing(Product::getCreatedAt));
                    break;
                case "newest":
                default:
                    products.sort(Comparator.comparing(Product::getCreatedAt).reversed());
                    break;
            }
        }
        try {
            objectMapper.writeValueAsString(products);
        } catch (Exception e) {
            System.err.println("SPRING BOOT OBJECTMAPPER ERROR IN PRODUCTS: " + e.getMessage());
            e.printStackTrace();
        }

        return ResponseEntity.ok(products);
    }

    @GetMapping("/products/{id}")
    public ResponseEntity<?> getProductById(@PathVariable("id") Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Product not found with ID: " + id));
        return ResponseEntity.ok(product);
    }

    @PostMapping("/admin/products")
    public ResponseEntity<?> createProduct(@Valid @RequestBody Map<String, Object> payload) {
        String sku = (String) payload.get("sku");
        String name = (String) payload.get("name");

        if (productRepository.existsBySku(sku)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Product SKU already exists"));
        }
        if (productRepository.existsByName(name)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Product name already exists"));
        }

        Product product = new Product();
        mapPayloadToProduct(payload, product);

        product = productRepository.save(product);

        // Low stock alert if stock is 0 on creation
        if (product.getStockQuantity() == 0) {
            notificationRepository.save(new Notification("Product out of stock: " + product.getName(), "OUT_OF_STOCK"));
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(product);
    }

    @PutMapping("/admin/products/{id}")
    public ResponseEntity<?> updateProduct(@PathVariable("id") Long id, @Valid @RequestBody Map<String, Object> payload) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Product not found with ID: " + id));

        String sku = (String) payload.get("sku");
        if (sku != null && !sku.equalsIgnoreCase(product.getSku()) && productRepository.existsBySku(sku)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Product SKU already exists"));
        }

        int oldStock = product.getStockQuantity();
        mapPayloadToProduct(payload, product);
        product = productRepository.save(product);

        // Notify low stock if stock dropped
        if (product.getStockQuantity() <= 5 && product.getStockQuantity() > 0 && oldStock > 5) {
            notificationRepository.save(new Notification("Product running low on stock (" + product.getStockQuantity() + " left): " + product.getName(), "LOW_STOCK"));
        } else if (product.getStockQuantity() == 0 && oldStock > 0) {
            notificationRepository.save(new Notification("Product is out of stock: " + product.getName(), "OUT_OF_STOCK"));
        }

        return ResponseEntity.ok(product);
    }

    @DeleteMapping("/admin/products/{id}")
    public ResponseEntity<?> deleteProduct(@PathVariable("id") Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Product not found with ID: " + id));

        // Soft delete
        product.setIsDeleted(true);
        productRepository.save(product);

        return ResponseEntity.ok(Map.of("message", "Product soft deleted. This product can be restored later."));
    }

    @PostMapping("/admin/products/{id}/restore")
    public ResponseEntity<?> restoreProduct(@PathVariable("id") Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Product not found with ID: " + id));

        product.setIsDeleted(false);
        productRepository.save(product);

        return ResponseEntity.ok(Map.of("message", "Product restored successfully."));
    }

    // --- CATEGORIES SECTION ---
    
    @GetMapping("/categories")
    public ResponseEntity<?> getAllCategories() {
        return ResponseEntity.ok(categoryRepository.findAll());
    }

    @PostMapping("/admin/categories")
    public ResponseEntity<?> createCategory(@RequestBody Map<String, String> payload) {
        String name = payload.get("name");
        String slug = payload.get("slug");
        String description = payload.get("description");

        if (name == null || name.trim().isEmpty() || slug == null || slug.trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Name and slug are required"));
        }
        if (categoryRepository.existsByName(name)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Category name already exists"));
        }
        if (categoryRepository.existsBySlug(slug)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Category slug already exists"));
        }

        Category category = new Category();
        category.setName(name);
        category.setSlug(slug);
        category.setDescription(description);

        category = categoryRepository.save(category);
        return ResponseEntity.status(HttpStatus.CREATED).body(category);
    }

    @PutMapping("/admin/categories/{id}")
    public ResponseEntity<?> updateCategory(@PathVariable("id") Long id, @RequestBody Map<String, String> payload) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Category not found"));

        String name = payload.get("name");
        if (name != null && !name.equalsIgnoreCase(category.getName()) && categoryRepository.existsByName(name)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Category name already exists"));
        }

        if (name != null) category.setName(name);
        if (payload.containsKey("slug")) category.setSlug(payload.get("slug"));
        if (payload.containsKey("description")) category.setDescription(payload.get("description"));

        category = categoryRepository.save(category);
        return ResponseEntity.ok(category);
    }

    @DeleteMapping("/admin/categories/{id}")
    public ResponseEntity<?> deleteCategory(@PathVariable("id") Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Category not found"));

        categoryRepository.delete(category);
        return ResponseEntity.ok(Map.of("message", "Category deleted successfully"));
    }

    // --- BRANDS ---
    @GetMapping("/brands")
    public ResponseEntity<?> getAllBrands() {
        return ResponseEntity.ok(brandRepository.findAll());
    }

    // --- HELPERS ---
    private void mapPayloadToProduct(Map<String, Object> payload, Product product) {
        product.setName((String) payload.get("name"));
        product.setSku((String) payload.get("sku"));
        
        // Generate slug
        if (payload.containsKey("slug")) {
            product.setSlug((String) payload.get("slug"));
        } else {
            product.setSlug(product.getName().toLowerCase().replaceAll("[^a-z0-9]+", "-"));
        }

        product.setDescription((String) payload.get("description"));
        
        Object priceVal = payload.get("price");
        if (priceVal instanceof Number) {
            product.setPrice(BigDecimal.valueOf(((Number) priceVal).doubleValue()));
        } else if (priceVal instanceof String) {
            product.setPrice(new BigDecimal((String) priceVal));
        }

        Object discountVal = payload.get("discountPercentage");
        if (discountVal instanceof Number) {
            product.setDiscountPercentage(BigDecimal.valueOf(((Number) discountVal).doubleValue()));
        } else if (discountVal instanceof String) {
            product.setDiscountPercentage(new BigDecimal((String) discountVal));
        }

        Object stockVal = payload.get("stockQuantity");
        if (stockVal instanceof Number) {
            product.setStockQuantity(((Number) stockVal).intValue());
        }

        Object warrantyVal = payload.get("warrantyMonths");
        if (warrantyVal instanceof Number) {
            product.setWarrantyMonths(((Number) warrantyVal).intValue());
        }

        product.setModelNumber((String) payload.get("modelNumber"));

        // Relations
        if (payload.containsKey("categoryId")) {
            Long catId = Long.valueOf(payload.get("categoryId").toString());
            product.setCategory(categoryRepository.findById(catId).orElseThrow(() -> new NoSuchElementException("Category not found")));
        }
        if (payload.containsKey("brandId")) {
            Long brandId = Long.valueOf(payload.get("brandId").toString());
            product.setBrand(brandRepository.findById(brandId).orElseThrow(() -> new NoSuchElementException("Brand not found")));
        }
        if (payload.containsKey("subCategoryId")) {
            Long subId = Long.valueOf(payload.get("subCategoryId").toString());
            product.setSubCategory(subCategoryRepository.findById(subId).orElseThrow(() -> new NoSuchElementException("SubCategory not found")));
        }

        // Image URL mapping
        if (payload.containsKey("imageUrl")) {
            String imageUrl = (String) payload.get("imageUrl");
            product.getImages().clear();
            if (imageUrl != null && !imageUrl.trim().isEmpty()) {
                com.melodymart.product.entity.ProductImage img = new com.melodymart.product.entity.ProductImage();
                img.setProduct(product);
                img.setImageUrl(imageUrl.trim());
                img.setIsPrimary(true);
                img.setDisplayOrder(1);
                product.getImages().add(img);
            }
        }
    }
}
