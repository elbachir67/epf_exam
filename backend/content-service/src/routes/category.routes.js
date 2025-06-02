const express = require("express");
const { body } = require("express-validator");
const categoryController = require("../controllers/category.controller");
const questionController = require("../controllers/question.controller");
const { verifyToken } = require("../middleware/auth.middleware");

const router = express.Router();

// Validation middleware
const validateCategory = [
  body("name")
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage("Name must be between 2 and 50 characters"),
  body("description")
    .trim()
    .isLength({ min: 5, max: 200 })
    .withMessage("Description must be between 5 and 200 characters"),
  body("color")
    .optional()
    .matches(/^#[0-9A-F]{6}$/i)
    .withMessage("Color must be a valid hex color"),
  body("icon").optional().isString().withMessage("Icon must be a string"),
];

// Routes
router.get("/", categoryController.getAllCategories);
router.post(
  "/",
  verifyToken,
  validateCategory,
  categoryController.createCategory
);
router.get("/:id", categoryController.getCategoryById);
router.put(
  "/:id",
  verifyToken,
  validateCategory,
  categoryController.updateCategory
);
router.delete("/:id", verifyToken, categoryController.deleteCategory);
// Dans category.routes.js, ajoutez temporairement :
router.post("/init", async (req, res) => {
  try {
    const initializeDatabase = require("../config/db-init");
    await initializeDatabase();

    const categories = await Category.find({ isActive: true });
    res.json({
      success: true,
      message: "Categories initialized",
      data: categories,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Questions by category
router.get("/:categoryId/questions", questionController.getQuestionsByCategory);

module.exports = router;
