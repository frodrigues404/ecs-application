const express = require("express");
const axios =  require("axios");

const app = express();
const port = 3000;

const indexPage = `
    <h3>Hello From ECS</h3>
    <p>What would you like to see?</p>
    <ul>
        <li><a href="/dogs">Random Dog</a></li>
    </ul>
`;

app.get("/", (req, res) => {
  res.send(indexPage);
});

app.get("/healthcheck", (req, res) => {
    try{
        res.sendStatus(200);
    }catch(error){
        res.sendStatus(500);
    }
});

app.get("/dogs", async (req, res) => {
    try{
        const response = await axios.get('https://dog.ceo/api/breeds/image/random');
        console.log(JSON.stringify(response.data));
        const { message: dogImage } = response.data;
        res.send(`
        <img src="${dogImage}" alt="random dog" style="max-width: 500px" />
        `);
    } catch(error){
        console.error(JSON.stringify(error));
        res.sendStatus(500);
        res.send(error.message);
    }
});

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
});