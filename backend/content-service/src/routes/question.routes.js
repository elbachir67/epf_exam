const express = require("express");
const { body } = require("express-validator");
const questionController = require("../controllers/question.controller");
const answerController = require("../controllers/answer.controller");
const { verifyToken, optionalAuth } = require("../middleware/auth.middleware");

const router = express.Router();

// Validation middleware
const validateQuestion = [
  body("title")
    .trim()
    .isLength({ min: 5, max: 200 })
    .withMessage("Title must be between 5 and 200 characters"),
  body("content")
    .trim()
    .isLength({ min: 10, max: 5000 })
    .withMessage("Content must be between 10 and 5000 characters"),
  body("categoryId").isMongoId().withMessage("Invalid category ID"),
  body("tags").optional().isArray().withMessage("Tags must be an array"),
  body("tags.*")
    .optional()
    .isString()
    .isLength({ max: 30 })
    .withMessage("Each tag must be a string with max 30 characters"),
];

const validateAnswer = [
  body("content")
    .trim()
    .isLength({ min: 5, max: 3000 })
    .withMessage("Answer content must be between 5 and 3000 characters"),
];

// Routes
router.post(
  "/",
  verifyToken,
  validateQuestion,
  questionController.createQuestion
);
router.get("/search", optionalAuth, questionController.searchQuestions);
router.get("/:id", optionalAuth, questionController.getQuestionById);
router.put(
  "/:id",
  verifyToken,
  validateQuestion,
  questionController.updateQuestion
);
router.delete("/:id", verifyToken, questionController.deleteQuestion);

// Answers routes
router.post(
  "/:questionId/answers",
  verifyToken,
  validateAnswer,
  answerController.createAnswer
);
router.get("/:questionId/answers", answerController.getAnswersByQuestion);
// Ajouter après les imports, avant les routes existantes
router.get("/test-auth", verifyToken, (req, res) => {
  res.json({
    success: true,
    message: "Authentication successful",
    user: req.user,
  });
});

// Route de debug - à retirer plus tard
router.get("/debug/:id", async (req, res) => {
  try {
    const question = await Question.findById(req.params.id).populate(
      "categoryId",
      "name description color icon"
    );

    res.json({
      success: true,
      rawQuestion: question,
      data: question,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
