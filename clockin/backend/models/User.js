const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  // age: { type: String, required: true },
  // gender: { type: String, required: true },
  // contactNumber: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  // type: { type: String, enum: ['admin', 'editor', 'viewer'], default: 'editor' }, // Default to 'editor'
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  // address: { type: String, required: true },
  // isActive: { type: Boolean, default: true },
  profilePicture: { type: String, default: '' },
  notificationSettings: {
    enabled: { type: Boolean, default: true },
    taskReminders: { type: Boolean, default: true },
    socialInteractions: { type: Boolean, default: true },
    ringtone: { type: String, default: 'default' },
  },
  theme: { type: String, enum: ['light', 'dark', 'system'], default: 'system' },
});

module.exports = mongoose.model.userSchema || mongoose.model('User', userSchema);