const express = require('express');
// import functions
const { getTask, createTask, updateTask, deleteTask } = require('../controllers/taskController');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');


router.route('/').get(authMiddleware, getTask).post(authMiddleware, createTask);
router.route('/:id').put(authMiddleware, updateTask).delete(authMiddleware, deleteTask);
module.exports = router;