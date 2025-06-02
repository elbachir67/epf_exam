const Answer = require('../models/answer.model');
const Question = require('../models/question.model');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

class AnswerController {
  async createAnswer(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array()
        });
      }

      const { questionId } = req.params;
      const { content } = req.body;
      const { username, userId } = req.user;

      // Verify question exists
      const question = await Question.findById(questionId);
      if (!question || !question.isActive) {
        return res.status(404).json({
          success: false,
          error: 'Question not found'
        });
      }

      if (question.isClosed) {
        return res.status(400).json({
          success: false,
          error: 'This question is closed for new answers'
        });
      }

      const answer = new Answer({
        questionId,
        content,
        authorId: userId,
        authorName: username
      });

      const savedAnswer = await answer.save();

      logger.info(`Answer created for question ${questionId} by ${username}`);

      res.status(201).json({
        success: true,
        data: savedAnswer
      });
    } catch (error) {
      logger.error('Error creating answer:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to create answer'
      });
    }
  }

  async voteAnswer(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array()
        });
      }

      const { answerId } = req.params;
      const { vote } = req.body;
      const { userId } = req.user;

      if (![1, -1].includes(vote)) {
        return res.status(400).json({
          success: false,
          error: 'Vote must be 1 (upvote) or -1 (downvote)'
        });
      }

      const answer = await Answer.findById(answerId);
      if (!answer || !answer.isActive) {
        return res.status(404).json({
          success: false,
          error: 'Answer not found'
        });
      }

      // Prevent self-voting
      if (answer.authorId === userId) {
        return res.status(400).json({
          success: false,
          error: 'You cannot vote on your own answer'
        });
      }

      // Check if user already voted
      const existingVoteIndex = answer.votes.findIndex(
        v => v.userId === userId
      );

      if (existingVoteIndex !== -1) {
        const existingVote = answer.votes[existingVoteIndex];
        
        if (existingVote.vote === vote) {
          // Remove vote (toggle off)
          answer.votes.splice(existingVoteIndex, 1);
          answer.score -= vote;
        } else {
          // Change vote
          answer.score -= existingVote.vote;
          answer.score += vote;
          existingVote.vote = vote;
        }
      } else {
        // Add new vote
        answer.votes.push({ userId, vote });
        answer.score += vote;
      }

      const updatedAnswer = await answer.save();

      logger.info(`Vote recorded for answer ${answerId} by ${userId}`);

      res.json({
        success: true,
        data: updatedAnswer
      });
    } catch (error) {
      logger.error('Error voting for answer:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to vote for answer'
      });
    }
  }

  async acceptAnswer(req, res) {
    try {
      const { answerId } = req.params;
      const { userId } = req.user;

      const answer = await Answer.findById(answerId).populate('questionId');
      
      if (!answer || !answer.isActive) {
        return res.status(404).json({
          success: false,
          error: 'Answer not found'
        });
      }

      // Only question author can accept answers
      if (answer.questionId.authorId !== userId) {
        return res.status(403).json({
          success: false,
          error: 'Only the question author can accept an answer'
        });
      }

      // Remove accepted status from other answers
      await Answer.updateMany(
        { questionId: answer.questionId._id, isAccepted: true },
        { isAccepted: false }
      );

      // Accept this answer
      answer.isAccepted = true;
      const updatedAnswer = await answer.save();

      logger.info(`Answer ${answerId} accepted for question ${answer.questionId._id}`);

      res.json({
        success: true,
        data: updatedAnswer
      });
    } catch (error) {
      logger.error('Error accepting answer:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to accept answer'
      });
    }
  }

  async getAnswersByQuestion(req, res) {
    try {
      const { questionId } = req.params;

      // Verify question exists
      const question = await Question.findById(questionId);
      if (!question || !question.isActive) {
        return res.status(404).json({
          success: false,
          error: 'Question not found'
        });
      }

      const answers = await Answer.find({ 
        questionId, 
        isActive: true 
      })
        .sort({ isAccepted: -1, score: -1, createdAt: -1 })
        .select('-__v');

      res.json({
        success: true,
        data: answers
      });
    } catch (error) {
      logger.error('Error fetching answers:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch answers'
      });
    }
  }

  async updateAnswer(req, res) {
    try {
      const { answerId } = req.params;
      const { content } = req.body;
      const { userId } = req.user;

      const answer = await Answer.findById(answerId);
      
      if (!answer || !answer.isActive) {
        return res.status(404).json({
          success: false,
          error: 'Answer not found'
        });
      }

      if (answer.authorId !== userId) {
        return res.status(403).json({
          success: false,
          error: 'You can only edit your own answers'
        });
      }

      answer.content = content;
      const updatedAnswer = await answer.save();

      logger.info(`Answer updated: ${answerId} by ${userId}`);

      res.json({
        success: true,
        data: updatedAnswer
      });
    } catch (error) {
      logger.error('Error updating answer:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to update answer'
      });
    }
  }

  async deleteAnswer(req, res) {
    try {
      const { answerId } = req.params;
      const { userId } = req.user;

      const answer = await Answer.findById(answerId);
      
      if (!answer) {
        return res.status(404).json({
          success: false,
          error: 'Answer not found'
        });
      }

      if (answer.authorId !== userId) {
        return res.status(403).json({
          success: false,
          error: 'You can only delete your own answers'
        });
      }

      answer.isActive = false;
      await answer.save();

      logger.info(`Answer deleted: ${answerId} by ${userId}`);

      res.json({
        success: true,
        message: 'Answer deleted successfully'
      });
    } catch (error) {
      logger.error('Error deleting answer:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to delete answer'
      });
    }
  }
}

module.exports = new AnswerController();
