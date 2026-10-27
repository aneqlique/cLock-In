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
  timeFormat: { type: String, enum: ['12h', '24h'], default: '12h' },
  // User-defined task categories; color is an index into the app's tint palette
  categories: {
    type: [{
      _id: false,
      key: { type: String, required: true, trim: true, maxlength: 40 },
      name: { type: String, required: true, trim: true, maxlength: 20 },
      color: { type: Number, min: 0, max: 7, default: 0 },
      icon: { type: String, default: 'spa' },
    }],
    default: () => [
      { key: 'school', name: 'School', color: 0, icon: 'school' },
      { key: 'work', name: 'Work', color: 1, icon: 'work' },
      { key: 'self', name: 'Self', color: 2, icon: 'spa' },
      { key: 'house', name: 'House', color: 3, icon: 'home' },
    ],
  },
});

module.exports = mongoose.model.userSchema || mongoose.model('User', userSchema);