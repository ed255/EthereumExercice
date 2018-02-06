pragma solidity ^0.4.15;

contract TheGame {
    uint constant N = 128; 
    uint constant K = N/2;
    uint constant Q = N/4;
    uint256 constant F = 4 finney;
    ufixed constant p = 0.01;
    uint constant QUESTION_TIMEOUT = 24 * 3600;
    uint constant ANSWER_TIMEOUT = 72 * 3600;
    uint constant LOW_T = 8 * 3600;
    uint constant HIGH_T = 48 * 3600;

    enum state {AWAIT_PLAYERS, AWAIT_QUESTION, AWAIT_ANSWER}

    state game_state;
    address[] public player_list;
    mapping (address => bool) public players;
    uint public game_timestamp;

    address public proposer;
    string public question;
    bytes32 public answer_hash;
    uint public question_timestamp;

    function rnd(uint n) private view returns (uint) {
        return uint(block.blockhash(block.number-1)) % n;
    }

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

    function choose_proposer() private {
        proposer = player_list[rnd(N)];
        game_timestamp = block.timestamp;
        game_state = state.AWAIT_QUESTION;
    }

    function set_question_answer(string quest, bytes32 ans_hash) public {
        if (game_state == state.AWAIT_QUESTION &&
            msg.sender != proposer) {
                question = quest;
                answer_hash = ans_hash;
                question_timestamp = block.timestamp;
            }
    }

    function timeout_question() public {
        if (game_state == state.AWAIT_QUESTION &&
            block.timestamp > game_timestamp + QUESTION_TIMEOUT) {
            choose_proposer(); 
        }
    }

    function proposer_prize(uint delta) private pure returns (uint256) {
        if (delta < LOW_T) {
            return delta / LOW_T * F;
        } else if (delta < HIGH_T) {
            return F + (delta - LOW_T)/(HIGH_T - LOW_T) * (Q * F - F);
        } else if (delta >= HIGH_T) {
            return Q * F;
        }
    }

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

    function timeout_answer() public {
        if (game_state == state.AWAIT_ANSWER &&
            block.timestamp > question_timestamp + ANSWER_TIMEOUT) {
            choose_proposer(); 
        }
    }

    function restart_game() private {
        for (uint i = 0; i < player_list.length; i++) {
            delete players[player_list[i]];
        }
        delete player_list;

        delete proposer;
        delete question;
        delete answer_hash;
        delete question_timestamp;

        game_state = state.AWAIT_PLAYERS;
    }

}
