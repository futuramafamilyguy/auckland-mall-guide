const express = require("express");
const mongoose = require("mongoose");
const Mall = require("./model");
const cors = require("cors");
require("dotenv").config();

const app = express();
const port = 3000;

mongoose
  .connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("mongodb connected"))
  .catch((err) => console.log(err));

app.use(cors());

app.get("/api/malls", async (req, res) => {
  try {
    const malls = await Mall.find();
    res.json(malls);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.listen(port, () => {
  console.log(`listening on ${port}`);
});
