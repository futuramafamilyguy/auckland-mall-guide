MONGO_URI=${MONGO_URI:-"mongodb://localhost:27017/auckland-mall-guide"}

# Connect to MongoDB and run commands
mongosh "$MONGO_URI" <<EOF
// Check if the collection exists and insert data if it's not already there
db.malls.updateOne(
    { name: "southmall manurewa" },
    { 
        \$setOnInsert: { name: "southmall manurewa", location: "south auckland", review: "life's hard but rewa's harder", tier: "A" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "westfield manukau" },
    { 
        \$setOnInsert: { name: "westfield manukau", location: "south auckland", review: "hayman park next door makes it the best mall in auckland", tier: "S" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "botany town centre" },
    { 
        \$setOnInsert: { name: "botany town centre", location: "east auckland", review: "truly feels like a town centre. food court's weak", tier: "A" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "sylvia park" },
    { 
        \$setOnInsert: { name: "sylvia park", location: "east-central auckland", review: "pokehouse is chef's kiss", tier: "S" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "westfield newmarket" },
    { 
        \$setOnInsert: { name: "westfield newmarket", location: "central auckland", review: "how good a mall is is directly proportional to how good the surrounding is and newmarket is not it", tier: "B" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "ormiston town centre" },
    { 
        \$setOnInsert: { name: "ormiston town centre", location: "east auckland", review: "good vibes. food court is god tier. rest of mall is mid. like i've never gone there to buy anything before. barry curtis twin parks are legit. hard to rank. everything other than the mall itself is sick", tier: "A" }
    },
    { upsert: true }
);

EOF

echo "seed data complete. idempotency babyy"
