// // db.js
// const mongoose = require('mongoose');
// const { MONGO_URI } = process.env;

// const connectDB = async () => {
//   try {
//    const conn = await mongoose.connect(process.env.MONGO_URI, {
//       useNewUrlParser: true,
//       useUnifiedTopology: true,
//     });
//     console.log(`MongoDB Connected: ${conn.connection.host}`);
//   } catch (err) {
//     console.error(`Error: ${err.message}`);
//     process.exit(1);
//   }
// };


// module.exports = connectDB;

// src/config/db.js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const uri =  process.env.MONGO_URI; 
    await mongoose.connect(uri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      // useCreateIndex: true, // not needed in latest mongoose
    });
    console.log('MongoDB connected (Atlas)');
  } catch (err) {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  }
};

module.exports = connectDB;
