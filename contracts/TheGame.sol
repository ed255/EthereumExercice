pragma solidity ^0.4.15;

/* Test

$ ganache-cli -a 4

var accounts;
web3.eth.getAccounts(function(err,res) { accounts = res; });

var tg = TheGame.at(TheGame.address)
tg.get_state()
tg.join_game({from: accounts[0], value: web3.toWei(4, 'finney')})
tg.join_game({from: accounts[1], value: web3.toWei(4, 'finney')})
tg.join_game({from: accounts[2], value: web3.toWei(4, 'finney')})
tg.join_game({from: accounts[3], value: web3.toWei(4, 'finney')})

tg.get_state()
tg.get_player_list()

tg.get_proposer()

tg.set_question_answer("What did the computer eat on the moon?", web3.sha3("space bars"), {from: tg.get_proposer()})

tg.get_state()
tg.guess_answer("space bars", {from: accounts[0]})

tg.get_state()

*/

contract TheGame {
    //uint constant N = 128; 
    uint constant N = 4; 
    uint constant K = N/2;
    uint constant Q = N/4;
    uint256 constant F = 4 finney;
    ufixed constant p = 0.01;
    uint constant QUESTION_TIMEOUT = 24 * 3600;
    uint constant ANSWER_TIMEOUT = 72 * 3600;
    uint constant LOW_T = 8 * 3600;
    uint constant HIGH_T = 48 * 3600;

    enum state {AWAIT_PLAYERS, AWAIT_QUESTION, AWAIT_ANSWER}

    state public game_state = state.AWAIT_PLAYERS;
    address[] public player_list;
    mapping (address => bool) public players;
    uint public game_timestamp;

    address public proposer;
    string public question;
    bytes32 public answer_hash;
    uint public question_timestamp;

    function get_player_list() public view returns (address[]) {
        return player_list;
    }

    function get_state() public view returns (state) {
        return game_state;
    }

    function get_proposer() public view returns (address) {
        return proposer;
    }

    function get_question() public view returns (string) {
        return question;
    }

    function get_pot() public view returns (uint256) {
        return this.balance;
    }

    function rnd(uint n) private view returns (uint) {
        return uint(block.blockhash(block.number-1)) % n;
    }

    function join_game() public payable {
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
            msg.sender == proposer) {
                question = quest;
                answer_hash = ans_hash;
                question_timestamp = block.timestamp;
                game_state = state.AWAIT_ANSWER;
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
            if (sha3(answer) == answer_hash) {
                uint256 prize;
                uint256 prop_prize = proposer_prize(block.timestamp - question_timestamp);
                if (rnd(128) == 42) {
                    prize = this.balance - prop_prize;    
                } else {
                    prize = K * F;
                }
                msg.sender.transfer(prize);
                proposer.transfer(prop_prize);
                clear_game();
                game_state = state.AWAIT_PLAYERS;
            }
        }
    }

    function timeout_answer() public {
        if (game_state == state.AWAIT_ANSWER &&
            block.timestamp > question_timestamp + ANSWER_TIMEOUT) {
            choose_proposer(); 
        }
    }

    function clear_game() private {
        for (uint i = 0; i < player_list.length; i++) {
            delete players[player_list[i]];
        }
        delete player_list;

        delete proposer;
        delete question;
        delete answer_hash;
        delete question_timestamp;
    }
}
