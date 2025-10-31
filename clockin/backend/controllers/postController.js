const Post = require('../models/Post');
const Task = require('../models/Task');
const User = require('../models/User');
const mongoose = require('mongoose');

// Get all public posts
const getPosts = async (req, res) => {
  try {
    const posts = await Post.find()
      .sort({ createdAt: -1 })
      .populate('userId', 'username')
      .lean();
    
    res.status(200).json(posts);
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ message: 'Failed to fetch posts', error: error.message });
  }
};

// Create or update post when task is set to public
const createOrUpdatePost = async (req, res) => {
  try {
    const { taskId, setPublic } = req.body;
    const userId = req.user.id;

    const task = await Task.findById(taskId);
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    if (task.user.toString() !== userId) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (setPublic) {
      // Create or update post
      let post = await Post.findOne({ taskId });
      
      if (post) {
        // Update existing post
        post.taskTitle = task.taskTitle;
        post.category = task.category;
        post.timeRange = task.timeRange;
        post.description = task.description;
        post.images = task.images;
        await post.save();
      } else {
        // Create new post
        post = await Post.create({
          userId,
          taskId,
          username: user.username,
          taskTitle: task.taskTitle,
          category: task.category,
          timeRange: task.timeRange,
          description: task.description,
          images: task.images
        });
      }
      
      res.status(200).json({ message: 'Post created/updated', post });
    } else {
      // Remove post if it exists
      await Post.findOneAndDelete({ taskId });
      res.status(200).json({ message: 'Post removed' });
    }
  } catch (error) {
    console.error('Error creating/updating post:', error);
    res.status(500).json({ message: 'Failed to create/update post', error: error.message });
  }
};

// Like or unlike a post
const toggleLike = async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user.id;

    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // Initialize likedBy array if it doesn't exist
    if (!post.likedBy) {
      post.likedBy = [];
    }

    const likedIndex = post.likedBy.findIndex(id => id.toString() === userId);

    if (likedIndex > -1) {
      // Unlike
      post.likedBy.splice(likedIndex, 1);
      post.likes = Math.max(0, post.likes - 1);
    } else {
      // Like
      const userIdObj = new mongoose.Types.ObjectId(userId);
      post.likedBy.push(userIdObj);
      post.likes += 1;
    }

    await post.save();
    res.status(200).json({ message: 'Like toggled', likes: post.likes, likedBy: post.likedBy });
  } catch (error) {
    console.error('Error toggling like:', error);
    res.status(500).json({ message: 'Failed to toggle like', error: error.message });
  }
};

// Add a comment
const addComment = async (req, res) => {
  try {
    const { postId } = req.params;
    const { comment } = req.body;
    const userId = req.user.id;

    if (!comment || comment.trim() === '') {
      return res.status(400).json({ message: 'Comment cannot be empty' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    post.comments.push({
      userId,
      username: user.username,
      comment: comment.trim()
    });

    await post.save();
    res.status(200).json({ message: 'Comment added', comments: post.comments });
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).json({ message: 'Failed to add comment', error: error.message });
  }
};

// Get comments for a post
const getComments = async (req, res) => {
  try {
    const { postId } = req.params;
    
    const post = await Post.findById(postId).select('comments');
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    res.status(200).json(post.comments);
  } catch (error) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ message: 'Failed to fetch comments', error: error.message });
  }
};

module.exports = {
  getPosts,
  createOrUpdatePost,
  toggleLike,
  addComment,
  getComments
};
