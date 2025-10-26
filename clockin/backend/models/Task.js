const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  taskTitle: { type: String, required: true },
  category: { type: String, enum: ['work', 'self', 'school', 'house'], default: 'self' },
  timeRange: { type: String, required: true },
  description: { type: String },
  status: { type: String, enum: ['pending', 'completed'], default: 'pending' },
}, { timestamps: true });

module.exports = mongoose.model.taskSchema || mongoose.model('Task', taskSchema);