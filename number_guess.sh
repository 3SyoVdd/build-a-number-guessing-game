#!/bin/bash
echo -e "Enter your username:"
read USERNAME

 # -t option to prevent  header
    # -A option to prevent spaces on output
 PSQL="psql --username=freecodecamp --dbname=number_guess -t -A -c"

# get username
USER_ID=$($PSQL "SELECT user_id, games_played, best_game from users WHERE name='$USERNAME'")

# new user
 if [[ -z $USER_ID ]]
  then
  echo "\nWelcome, $USERNAME! It looks like this is your first time here.\n"
   USER_ID_OUTPUT=$($PSQL "INSERT INTO users(name) values ('$USERNAME') returning user_id")
   #modify so that customer_id matches output
  USER_ID=$(echo $USER_ID_OUTPUT |grep -o ^[0-9]*)
 
else
# known user
#echo USER_ID $USER_ID
 IFS="|" read -r USER_ID GAMESPLAYED BESTGAME <<< "$USER_ID"
echo -e "\nWelcome back, $USERNAME! You have played $GAMESPLAYED games, and your best game took $BESTGAME guesses."

fi
#create Number between  1 and 1000;
SECNUM=$((1 + $RANDOM % 1000))
GUESS=0
NUMBEROFGUESSES=0



GUESS_AGAIN_FUNCTION (){
# if called with argument
if [[ $1 ]]
then
    #then output argument
    echo -e "\n$1"
#else
    #else output standard message
  #  echo "Guess the secret number between 1 and 1000:"
fi

#has to be printed every time
    echo -e "\nGuess the secret number between 1 and 1000:"

read NEWGUESS


re='^[0-9]+$'

if ! [[ $NEWGUESS =~ $re ]]
then
  # of not a number
  GUESS_AGAIN_FUNCTION "That is not an integer, guess again:"
else

    ((NUMBEROFGUESSES=NUMBEROFGUESSES+1))

  if (( NEWGUESS>SECNUM )) 
  then
  GUESS_AGAIN_FUNCTION "It's lower than that, guess again:"
  fi


  if (( NEWGUESS<SECNUM )) 
  then
  GUESS_AGAIN_FUNCTION "It's higher than that, guess again:"
  fi

  if (( NEWGUESS==SECNUM )) 
  then
      #increment games_played, update best game if current game is better than best game
    UPDATE_DB=$($PSQL "UPDATE users set games_played = coalesce(games_played,0) + 1, best_game= CASE WHEN best_game IS NULL or $NUMBEROFGUESSES<best_game THEN $NUMBEROFGUESSES ELSE best_game END where user_id='$USER_ID'")
    echo -e "\nYou guessed it in $NUMBEROFGUESSES tries. The secret number was $SECNUM. Nice job!"
    exit
  fi
  
fi

}

GUESS_AGAIN_FUNCTION 
