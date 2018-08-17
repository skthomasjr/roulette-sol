### Blockchain-based Mathematically Fair Roulette Table

roulette-sol is a mathematically fair roulette table that exists as multiple cooperative smart contracts on the Ethereum VM. Work is in progress!!!

### To Do

- Pull out dockerized dev environments for this repo
- optimize looping/for
- limit bet amount
- limit total bets
- what happens when the casino goes bankrupted
- what happens with no operators
- events on all contracts

```
docker compose up --detach --build workspace ganache
docker-compose exec workspace bash
docker-compose down --rmi all
```
