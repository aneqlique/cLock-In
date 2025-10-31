const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  taskTitle: { type: String, required: true },
  category: { type: String, enum: ['work', 'self', 'school', 'house'], default: 'self' },
  timeRange: { type: String, required: true },
  description: { type: String },
  status: { type: String, enum: ['pending', 'completed'], default: 'pending' },
  images: { 
    type: [String], 
    default: [],
    validate: {
      validator: function(v) {
        return v.length <= 10;
      },
      message: 'Cannot upload more than 10 images per task'
    }
  },
  setPublic: { type: Boolean, default: false },
  completedAt: { type: Date },
  alarm: {
    enabled: { type: Boolean, default: false },
    minutesBefore: { type: Number, enum: [5, 10, 30, 60], default: 10 },
  },
}, { timestamps: true });

module.exports = mongoose.model.taskSchema || mongoose.model('Task', taskSchema);