const mongoose = require('mongoose');

const VoteSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true
  },
  vote: {
    type: Number,
    required: true,
    enum: [1, -1]
  }
}, { _id: false });

const AnswerSchema = new mongoose.Schema({
  questionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Question',
    required: [true, 'Question ID is required'],
    index: true
  },
  content: {
    type: String,
    required: [true, 'Answer content is required'],
    trim: true,
    minlength: [5, 'Answer must be at least 5 characters'],
    maxlength: [3000, 'Answer cannot exceed 3000 characters']
  },
  authorId: {
    type: String,
    required: true,
    index: true
  },
  authorName: {
    type: String,
    required: true
  },
  votes: [VoteSchema],
  score: {
    type: Number,
    default: 0
  },
  isAccepted: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
AnswerSchema.index({ questionId: 1, score: -1 });
AnswerSchema.index({ authorId: 1, createdAt: -1 });
AnswerSchema.index({ isActive: 1, createdAt: -1 });

// Update question answer count on save
AnswerSchema.post('save', async function() {
  const Question = mongoose.model('Question');
  const count = await mongoose.model('Answer').countDocuments({ 
    questionId: this.questionId,
    isActive: true 
  });
  await Question.updateOne(
    { _id: this.questionId },
    { answerCount: count }
  );
});

// Update question answer count on remove
AnswerSchema.post('remove', async function() {
  const Question = mongoose.model('Question');
  const count = await mongoose.model('Answer').countDocuments({ 
    questionId: this.questionId,
    isActive: true 
  });
  await Question.updateOne(
    { _id: this.questionId },
    { answerCount: count }
  );
});

module.exports = mongoose.model('Answer', AnswerSchema);
