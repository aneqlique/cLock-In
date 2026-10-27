# Cloudinary Setup for Image Upload

## Required Environment Variables

Add the following variables to your `.env` file:

```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## How to Get Cloudinary Credentials

1. Sign up for a free account at [Cloudinary](https://cloudinary.com/)
2. Go to your Dashboard
3. Copy the following from your dashboard:
   - Cloud Name
   - API Key
   - API Secret
4. Add them to your `.env` file

## Features

- Upload up to 10 images per task
- Images are stored in the `clockin_tasks` folder in Cloudinary
- File size limit: 5MB per image
- Only image files are allowed
- Images are automatically optimized by Cloudinary
