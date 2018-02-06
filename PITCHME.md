# The Game
### An Ethereum Smart Contract quizz game

#HSLIDE
### Idea

Make a decentralized game where a player proposes a problem as a question and
the rest of the players try to guess the answer, with fees and prizes.

#HSLIDE
### Challenges

* Forbid cheating
* Incentivize users to play
* Incentivize the proposer submit a good problem (not too easy, not impossible)
* Achieve liveness (the game continues even if a player stops participating)

#HSLIDE
### Setup

1. Wait for N users to join the game (by paying a fee F)
2. Select one player at random that will submit a question and hash(answer)
3. Wait some time for another player to guess the right answer, or go to 2 after timeout
4. Winner gets a fraction of this round fees or the pot (contract valance) with a small probability
5. Clear data and go to 1

#HSLIDE
### Details

#### Timeouts

The contract implements a state machine that records the timestamp after every transition.  If a state exceeds a specified timeout, any user can call a timeout function to reset the game.

#### Incentivizing proposer

The choosen proposer has payed a fee but won't be guessing, so they may lose interest!  Reward them with a prize for good questions: low reward for questions answered quickly, high reward for answers that take more time.

#HSLIDE
### Attacks?

An attacker could register more than one player so that they are the question
proposer, then choose a question with a random answer which only they know.

#### Solution

Make the system such that this attacker loses money on average by following this strategy:

E(earnings) = - fees spent + E(prize) < 0
$$-mF + \frac{m}{N}\left[(1-p)(kF) + p((N-k)F\frac{1}{p}\right] < 0$$

#HSLIDE
#### Show me the code
```
function join_game() public {
    if (game_state == state.AWAIT_PLAYERS &&
        msg.value >= F) {
        player_list.push(msg.sender);
        players[msg.sender] = true;

        if (player_list.length == N) {
            proposer = player_list[rnd(N)];
            game_timestamp = block.timestamp;
            game_state = state.AWAIT_QUESTION;
        }
    }
}
```

#HSLIDE
#### Show me the code
```
function set_question_answer(string quest, bytes32 ans_hash) public {
    if (game_state == state.AWAIT_QUESTION &&
        msg.sender == proposer) {
            question = quest;
            answer_hash = ans_hash;
            question_timestamp = block.timestamp;
        }
}
```

#HSLIDE
#### Show me the code
```
function guess_answer(string answer) public {
    if (game_state == state.AWAIT_ANSWER &&
        players[msg.sender] == true &&
        msg.sender != proposer) {
        if (sha256(answer) == answer_hash) {
            uint256 prize;
            uint256 prop_prize = proposer_prize(block.timestamp - question_timestamp);
            if (rnd(128) == 42) {
                prize = this.balance - prop_prize;    
            } else {
                prize = K * F;
            }
            msg.sender.transfer(prize);
            proposer.transfer(prop_prize);
            restart_game();
        }
    }
}
```
