const express = require('express');
const { body } = require('express-validator');
const answerController = require('../controllers/answer.controller');
const { verifyToken } = require('../middleware/auth.middleware');

const router = express.Router();

// Validation middleware
const validateVote = [
  body('vote')
    .isInt({ min: -1, max: 1 })
    .not()
    .equals(0)
    .withMessage('Vote must be 1 (upvote) or -1 (downvote)')
];

const validateAnswerUpdate = [
  body('content')
    .trim()
    .isLength({ min: 5, max: 3000 })
    .withMessage('Answer content must be between 5 and 3000 characters')
];

// Routes
router.post('/:answerId/vote', verifyToken, validateVote, answerController.voteAnswer);
router.post('/:answerId/accept', verifyToken, answerController.acceptAnswer);
router.put('/:answerId', verifyToken, validateAnswerUpdate, answerController.updateAnswer);
router.delete('/:answerId', verifyToken, answerController.deleteAnswer);

module.exports = router;
