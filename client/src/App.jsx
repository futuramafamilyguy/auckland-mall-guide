import { useState, useEffect } from "react";
import "./App.css";

function App() {
  const [malls, setMalls] = useState([]);

  const fetchData = async () => {
    try {
      const response = await fetch(import.meta.env.VITE_API_URL);
      if (!response.ok) throw new Error("failed to load malls");
      const data = await response.json();
      const sortedMalls = data.sort((a, b) => {
        const tierOrder = [
          "S",
          "A",
          "B",
          "C",
          "D",
          "E",
          "F",
          "Z FOR ZOOWEEMAMA",
        ];
        return tierOrder.indexOf(a.tier) - tierOrder.indexOf(b.tier);
      });
      setMalls(sortedMalls);
    } catch (error) {
      console.error("error:", error);
      setError("Failed to load malls.");
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  return (
    <>
      <h1>auckland mall guide</h1>
      <p>rip west auckland and shore representation *~*</p>
      <br />
      <div id="mallsContainer">
        {malls.map((mall) => (
          <div key={mall.name} className="mall">
            <h2>{mall.name}</h2>
            <p>{`location: ${mall.location}`}</p>
            <p>{`tier: ${mall.tier}`}</p>
            <p className="review">{mall.review}</p>
          </div>
        ))}
      </div>
    </>
  );
}

export default App;
