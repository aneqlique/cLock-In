const Task = require('../models/Task');

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
    const{taskTitle, category, timeRange, description, status} = req.body;
    const newtask = await new Task({
        user: req.user.id,
        taskTitle, 
        category, 
        timeRange, 
        description, 
        status: status || 'pending' });

    const savedTask = await newtask.save();
    res.status(201).json(savedTask);

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const updateTask = async (req, res) => {
  try {
    const updated = await Task.findByIdAndUpdate(req.params.id, req.body, { new: true });
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
