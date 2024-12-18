const mongoose = require('mongoose');

const mallSchema = new mongoose.Schema({
  name: String,
  location: String,
  review: String,
  tier: String,
});

module.exports = mongoose.model('Mall', mallSchema);
