const cloudinary = require('../config/cloudinary');

const uploadImages = async (req, res) => {
  try {
    // Check if Cloudinary is configured
    if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      console.error('Cloudinary credentials not configured');
      return res.status(500).json({ 
        message: 'Image upload service not configured. Please set CLOUDINARY credentials in .env file' 
      });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'No images provided' });
    }

    if (req.files.length > 10) {
      return res.status(400).json({ message: 'Cannot upload more than 10 images' });
    }

    console.log(`Uploading ${req.files.length} images to Cloudinary...`);

    const uploadPromises = req.files.map((file, index) => {
      return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          { 
            folder: 'clockin_tasks',
            resource_type: 'image'
          },
          (error, result) => {
            if (error) {
              console.error(`Error uploading image ${index + 1}:`, error);
              reject(error);
            } else {
              console.log(`Successfully uploaded image ${index + 1}: ${result.secure_url}`);
              resolve(result.secure_url);
            }
          }
        );
        uploadStream.end(file.buffer);
      });
    });

    const imageUrls = await Promise.all(uploadPromises);
    console.log(`All ${imageUrls.length} images uploaded successfully`);
    res.status(200).json({ images: imageUrls });

  } catch (error) {
    console.error('Upload error details:', error);
    res.status(500).json({ 
      message: error.message || 'Failed to upload images',
      error: process.env.NODE_ENV === 'development' ? error.toString() : undefined
    });
  }
};

module.exports = { uploadImages };
