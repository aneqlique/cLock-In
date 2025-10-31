const Task = require('../models/Task');
const Post = require('../models/Post');
const User = require('../models/User');

const getTask = async (req, res) => {
  try {
    const usersId = req.user.id;
    const tasks = await Task.find({ user: usersId });
    res.json({ tasks });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createTask = async (req, res) => {
  try {
    // const userId = req.user.id;
    const{taskTitle, category, timeRange, description, status, images, setPublic} = req.body;
    const newtask = await new Task({
        user: req.user.id,
        taskTitle, 
        category, 
        timeRange, 
        description, 
        status: status || 'pending',
        images: images || [],
        setPublic: setPublic || false });

    const savedTask = await newtask.save();
    res.status(201).json(savedTask);

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const updateTask = async (req, res) => {
  try {
    const taskId = req.params.id;
    const userId = req.user.id;
    const updates = req.body;
    
    // Set completedAt when status changes to completed
    if (updates.status === 'completed' && !updates.completedAt) {
      updates.completedAt = new Date();
    }
    
    const updated = await Task.findByIdAndUpdate(taskId, updates, { new: true });
    
    // Handle post creation/deletion based on setPublic flag
    if (updates.hasOwnProperty('setPublic')) {
      if (updates.setPublic) {
        // Create or update post
        const user = await User.findById(userId);
        if (user) {
          let post = await Post.findOne({ taskId });
          
          if (post) {
            // Update existing post
            post.taskTitle = updated.taskTitle;
            post.category = updated.category;
            post.timeRange = updated.timeRange;
            post.description = updated.description;
            post.images = updated.images;
            await post.save();
          } else {
            // Create new post
            await Post.create({
              userId,
              taskId,
              username: user.username,
              taskTitle: updated.taskTitle,
              category: updated.category,
              timeRange: updated.timeRange,
              description: updated.description,
              images: updated.images || []
            });
          }
        }
      } else {
        // Remove post if it exists
        await Post.findOneAndDelete({ taskId });
      }
    }
    
    res.json(updated);

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const deleteTask = async (req, res) => {
  try {
    await Task.findByIdAndDelete(req.params.id);
    res.json({ message: 'Task deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = { getTask, createTask, updateTask, deleteTask };
