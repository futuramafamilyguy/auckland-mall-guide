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
        \$setOnInsert: { name: "sylvia park", location: "east-central auckland", review: "this one is S tier out of respect for general consensus. 8/10 tamaki makaurauers would say sylvia park is the best mall", tier: "S" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "westfield newmarket" },
    { 
        \$setOnInsert: { name: "westfield newmarket", location: "central auckland", review: "how good a mall is is directly proportional to how good its surrounding is and newmarket is not it", tier: "B" }
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

db.malls.updateOne(
    { name: "lynnmall shopping centre" },
    { 
        \$setOnInsert: { name: "lynnmall shopping centre", location: "west-central auckland", review: "mid af but gets brownie points for being my team lead's favourite mall", tier: "B" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "albany westfield" },
    { 
        \$setOnInsert: { name: "albany westfield", location: "northshore", review: "a recent article ranking auckland malls ranked this one first so out of spite this is an F tier. even tho its next to my office and i have some pre good memories there with my coworkers :')", tier: "F" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "hunters plaza" },
    { 
        \$setOnInsert: { name: "hunters plaza", location: "south auckland", review: "theres some sentimental value with this one but truth is i pretty much never go there these days so gotta rank fairly", tier: "C" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "westfield st lukes" },
    { 
        \$setOnInsert: { name: "westfield st lukes", location: "west-central auckland", review: "worst westfield in auckland. its worst than the one in christchurch too", tier: "C" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "atrium on elliott" },
    { 
        \$setOnInsert: { name: "atrium on elliott", location: "central auckland", review: "yikes", tier: "Z FOR ZOOWEEMAMA" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "southpoint mall" },
    { 
        \$setOnInsert: { name: "southpoint mall", location: "south auckland", review: "honestly nice spot. its just barely a mall", tier: "C" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "chinatown" },
    { 
        \$setOnInsert: { name: "chinatown", location: "east auckland", review: "my parents didnt bring me to this country just so i could go to chinatown. F for chinatown", tier: "F" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "commerical bay" },
    { 
        \$setOnInsert: { name: "commerical bay", location: "central auckland", review: "i walk past it everyday to get to work so the noveltys worn off", tier: "C" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "royal oak mall" },
    { 
        \$setOnInsert: { name: "royal oak mall", location: "south-central auckland", review: "hunters plaza without the sentimental value", tier: "D" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "dress smart" },
    { 
        \$setOnInsert: { name: "dress smart", location: "south-central auckland", review: "found out the other day the name could be either interpreted as dress smart or dress mart. clever hahahahahaha. D tier", tier: "D" }
    },
    { upsert: true }
);

db.malls.updateOne(
    { name: "mānawa bay" },
    { 
        \$setOnInsert: { name: "mānawa bay", location: "south auckland", review: "too many rich tourists here", tier: "D" }
    },
    { upsert: true }
);

EOF

echo "seed data complete. idempotency babyy"
