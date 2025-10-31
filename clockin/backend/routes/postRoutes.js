const express = require('express');
const {
  getPosts,
  createOrUpdatePost,
  toggleLike,
  addComment,
  getComments
} = require('../controllers/postController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Get all posts
router.get('/', authMiddleware, getPosts);

// Create or update post
router.post('/', authMiddleware, createOrUpdatePost);

// Toggle like on a post
router.post('/:postId/like', authMiddleware, toggleLike);

// Add comment to a post
router.post('/:postId/comment', authMiddleware, addComment);

// Get comments for a post
router.get('/:postId/comments', authMiddleware, getComments);

module.exports = router;
