# The Game
### An Ethereum Smart Contract quizz game

#HSLIDE
# Idea

Make a decentralized game where a player proposes a problem as a question and
the rest of the players try to guess the answer, with fees and prizes.

#HSLIDE
# Challenges

* Forbid cheating
* Incentivize users to play
* Incentivize the proposer submit a good problem (not too easy, not impossible)
* Achieve liveness (the game continues even if a player stops participating)

#HSLIDE
# Setup

1. Wait for N users to join the game (by paying a fee F)
2. Select one player at random that will submit a question and hash(answer)
3. Wait some time for another player to guess the right answer, or go to 2 after timeout
4. Winner gets a fraction of this round fees or the pot (contract valance) with a small probability
5. Clear data and go to 1

#HSLIDE
# Details

### Timeouts

The contract implements a state machine that records the timestamp after every transition.  If a state exceeds a specified timeout, any user can call a timeout function to reset the game.

### Incentivizing proposer

The choosen proposer has payed a fee but won't be guessing, so they may lose interest!  Reward them with a prize for good questions: low reward for questions answered quickly, high reward for answers that take more time.

#HSLIDE
# Attacks?

An attacker could register more than one player so that they are the question
proposer, then choose a question with a random answer which only they know.

### Solution

Make the system such that this attacker loses money on average by following this strategy:

E(earnings) = E(prize) - fees spent < 0
$$-mF + \frac{m}{N}*\left[(1-p)(kF) + p((N-k)F\frac{1}{p}\right]$$
