const Question = require("../models/question.model");
const Category = require("../models/category.model");
const { validationResult } = require("express-validator");
const logger = require("../utils/logger");

class QuestionController {
  async createQuestion(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array(),
        });
      }

      const { title, content, categoryId, tags } = req.body;
      const { username, userId } = req.user;

      // Verify category exists
      const category = await Category.findById(categoryId);
      if (!category || !category.isActive) {
        return res.status(400).json({
          success: false,
          error: "Invalid category",
        });
      }

      const question = new Question({
        title,
        content,
        categoryId,
        tags: tags || [],
        authorId: userId,
        authorName: username,
      });

      const savedQuestion = await question.save();
      await savedQuestion.populate("categoryId", "name description color icon");

      logger.info(`Question created: ${savedQuestion._id} by ${username}`);

      res.status(201).json({
        success: true,
        data: savedQuestion,
      });
    } catch (error) {
      logger.error("Error creating question:", error);
      res.status(500).json({
        success: false,
        error: "Failed to create question",
      });
    }
  }

  async getQuestionsByCategory(req, res) {
    try {
      const { categoryId } = req.params;
      const page = parseInt(req.query.page) || 1;
      const limit = Math.min(parseInt(req.query.limit) || 10, 50);
      const skip = (page - 1) * limit;

      // Verify category exists
      const category = await Category.findById(categoryId);
      if (!category || !category.isActive) {
        return res.status(404).json({
          success: false,
          error: "Category not found",
        });
      }

      const questions = await Question.find({
        categoryId,
        isActive: true,
      })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate("categoryId", "name description color icon")
        .select("-__v");

      const totalQuestions = await Question.countDocuments({
        categoryId,
        isActive: true,
      });

      const totalPages = Math.ceil(totalQuestions / limit);

      res.json({
        success: true,
        data: {
          questions,
          pagination: {
            currentPage: page,
            totalPages,
            totalItems: totalQuestions,
            hasMore: page < totalPages,
            itemsPerPage: limit,
          },
        },
      });
    } catch (error) {
      logger.error("Error fetching questions:", error);
      res.status(500).json({
        success: false,
        error: "Failed to fetch questions",
      });
    }
  }

  async getQuestionById(req, res) {
    try {
      const { id } = req.params;

      const question = await Question.findById(id)
        .populate("categoryId", "name description color icon")
        .populate({
          path: "answers",
          match: { isActive: true },
          options: {
            sort: { isAccepted: -1, score: -1, createdAt: -1 },
          },
        })
        .select("-__v");

      if (!question || !question.isActive) {
        return res.status(404).json({
          success: false,
          error: "Question not found",
        });
      }

      // Increment view count
      await Question.updateOne({ _id: id }, { $inc: { viewCount: 1 } });

      res.json({
        success: true,
        data: question,
      });
    } catch (error) {
      logger.error("Error fetching question:", error);
      res.status(500).json({
        success: false,
        error: "Failed to fetch question",
      });
    }
  }

  async searchQuestions(req, res) {
    try {
      const { q: query } = req.query;
      const page = parseInt(req.query.page) || 1;
      const limit = Math.min(parseInt(req.query.limit) || 10, 50);
      const skip = (page - 1) * limit;

      if (!query || query.trim().length < 2) {
        return res.status(400).json({
          success: false,
          error: "Search query must be at least 2 characters long",
        });
      }

      const searchFilter = {
        $text: { $search: query },
        isActive: true,
      };

      const questions = await Question.find(searchFilter)
        .sort({ score: { $meta: "textScore" }, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate("categoryId", "name description color icon")
        .select("-__v");

      const totalQuestions = await Question.countDocuments(searchFilter);
      const totalPages = Math.ceil(totalQuestions / limit);

      res.json({
        success: true,
        data: {
          questions,
          pagination: {
            currentPage: page,
            totalPages,
            totalItems: totalQuestions,
            hasMore: page < totalPages,
            itemsPerPage: limit,
          },
          query,
        },
      });
    } catch (error) {
      logger.error("Error searching questions:", error);
      res.status(500).json({
        success: false,
        error: "Failed to search questions",
      });
    }
  }

  async updateQuestion(req, res) {
    try {
      const { id } = req.params;
      const { title, content, tags } = req.body;
      const { userId } = req.user;

      const question = await Question.findById(id);

      if (!question) {
        return res.status(404).json({
          success: false,
          error: "Question not found",
        });
      }

      if (question.authorId !== userId) {
        return res.status(403).json({
          success: false,
          error: "You can only edit your own questions",
        });
      }

      question.title = title || question.title;
      question.content = content || question.content;
      question.tags = tags || question.tags;

      const updatedQuestion = await question.save();
      await updatedQuestion.populate(
        "categoryId",
        "name description color icon"
      );

      logger.info(`Question updated: ${id} by ${userId}`);

      res.json({
        success: true,
        data: updatedQuestion,
      });
    } catch (error) {
      logger.error("Error updating question:", error);
      res.status(500).json({
        success: false,
        error: "Failed to update question",
      });
    }
  }

  async deleteQuestion(req, res) {
    try {
      const { id } = req.params;
      const { userId } = req.user;

      const question = await Question.findById(id);

      if (!question) {
        return res.status(404).json({
          success: false,
          error: "Question not found",
        });
      }

      if (question.authorId !== userId) {
        return res.status(403).json({
          success: false,
          error: "You can only delete your own questions",
        });
      }

      question.isActive = false;
      await question.save();

      logger.info(`Question deleted: ${id} by ${userId}`);

      res.json({
        success: true,
        message: "Question deleted successfully",
      });
    } catch (error) {
      logger.error("Error deleting question:", error);
      res.status(500).json({
        success: false,
        error: "Failed to delete question",
      });
    }
  }
}

module.exports = new QuestionController();
