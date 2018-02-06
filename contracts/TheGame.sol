pragma solidity ^0.4.15;

contract TheGame {
    uint constant N = 128; 
    uint constant k = N/2;
    ufixed constant p = 0.01;
    uint constant QUESTION_TIMEOUT = 24 * 3600;
    uint constant ANSWER_TIMEOUT = 72 * 3600;

    enum state {AWAIT_PLAYERS, AWAIT_QUESTION, AWAIT_ANSWER};

    state game_state;
    address[] public player_list;
    mapping (address => bool) public players;
    uint public game_timestamp;

    address public proposer;
    string public question;
    bytes32 public answer_hash;
    uint public question_timestamp;

    function rnd(uint n) returns (uint) {
        return uint(block.blockhash(block.number-1)) % n;
    }

    function join_game() public {
        if (game_state == AWAIT_PLAYERS) {
            player_list.push(msg.sender);
            players[msg.sender] = true;

            if (player_list.length == N) {
                proposer = player_list[rnd(N)];
                game_timestamp = block.timestamp;
                game_state = AWAIT_QUESTION;
            }
        }
    }

    function choose_proposer() private {
        proposer = player_list[rnd(N)];
        game_timestamp = block.timestamp;
        game_state = AWAIT_QUESTION;
    }

    function set_question_answer(string quest, bytes32 ans_hash) public {
        if (game_state == AWAIT_QUESTION &&
            msg.sender != proposer) {
                question = quest;
                answer_hash = ans_hash;
                question_timestamp = block.timestamp;
            }
    }

    function timeout_question() public {
        if (game_state == AWAIT_QUESTION &&
            block.timestamp > game_timestamp + QUESTION_TIMEOUT) {
            choose_proposer(); 
        }
    }

    function guess_answer(string answer) public {
        if (game_state == AWAIT_ANSWER &&
            players[msg.sender] == true &&
            msg.sender != proposer) {
            if (sha256(answer) == answer_hash) {
                uint256 prize;
                if rnd(128) = 42 {
                    prize = self.balance;    
                } else {
                    prize = k * F;
                }
                msg.sender.transfer(prize);
                restart_game();
            }
        }
    }

    function timeout_answer() public {
        if (game_state == AWAIT_ANSWER &&
            block.timestamp > question_timestamp + ANSWER_TIMEOUT) {
            choose_proposer(); 
        }
    }

    function restart_game() private {
        for (uint i = 0; i < player_list.length; i++) {
            delete players[player_list[i]];
        }
        delete player_list

        delete proposer;
        delete question;
        delete answer_hash;
        delete question_timestamp;

        game_state = AWAIT_PLAYERS;
    }

}
