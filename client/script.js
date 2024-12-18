async function fetchData() {
  try {
    const response = await fetch("http://localhost:3000/api/malls");
    if (!response.ok) throw new Error("failed to load malls");

    const data = await response.json();

    renderMall(data);
  } catch (error) {
    console.error("Error:", error);
    document.getElementById("mallsContainer").innerText =
      "failed to load malls.";
  }
}

function renderMall(malls) {
  const container = document.getElementById("mallsContainer");
  container.innerHTML = "";

  const sortedMalls = malls.sort((a, b) => {
    const tierOrder = ["S", "A", "B", "C", "D", "E", "F", "Z FOR ZOOWEEMAMA"];
    return tierOrder.indexOf(a.tier) - tierOrder.indexOf(b.tier);
  });

  sortedMalls.forEach((mall) => {
    const mallDiv = document.createElement("div");
    mallDiv.className = "mall";

    const mallName = document.createElement("h2");
    mallName.textContent = mall.name;
    mallDiv.appendChild(mallName);

    const mallLocation = document.createElement("p");
    mallLocation.textContent = `location: ${mall.location}`;
    mallDiv.appendChild(mallLocation);

    const mallTier = document.createElement("p");
    mallTier.textContent = `tier: ${mall.tier}`;
    mallDiv.appendChild(mallTier);

    const mallReview = document.createElement("p");
    mallReview.textContent = mall.review;
    mallReview.style.fontStyle = "italic";
    mallDiv.appendChild(mallReview);

    container.appendChild(mallDiv);
  });
}

window.onload = fetchData;
