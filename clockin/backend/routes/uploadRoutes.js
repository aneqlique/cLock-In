const express = require('express');
const multer = require('multer');
const { uploadImages } = require('../controllers/uploadController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Configure multer to use memory storage
const storage = multer.memoryStorage();
const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB per file
  fileFilter: (req, file, cb) => {
    console.log('File received:', {
      fieldname: file.fieldname,
      originalname: file.originalname,
      mimetype: file.mimetype,
      encoding: file.encoding
    });
    
    // Accept if mimetype starts with 'image/' or if mimetype is not set (mobile uploads)
    if (!file.mimetype || file.mimetype.startsWith('image/') || file.mimetype === 'application/octet-stream') {
      cb(null, true);
    } else {
      console.error('Rejected file with mimetype:', file.mimetype);
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

router.post('/', authMiddleware, upload.array('images', 10), uploadImages);

module.exports = router;
