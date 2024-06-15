#!/bin/bash

# Define the filename for the reservations database
RESERVATIONS_FILE="data/reservations.txt"

# Function to remove a reservation
remove_reservation() {
    room_number=$1
    grep -v "^$room_number|" "$RESERVATIONS_FILE" > "$RESERVATIONS_FILE.tmp"
    mv "$RESERVATIONS_FILE.tmp" "$RESERVATIONS_FILE"
    echo "Room has been removed successfully"
}

# Function to list reservations
list_reservations() {
    if [ ! -s "$RESERVATIONS_FILE" ]; then
        echo "No reservations found."
    else
        sort -n "$RESERVATIONS_FILE" | awk -F '|' '{ printf "Room Number:%-10s Customer Name:%-20s CheckIn:%s  CheckOut:%s\n", $1, $2, $3, $4 }'
    fi
}

# Function to print the bill
bill() {
    echo "Enter the room number:"
    read room_number
    if grep -q "^$room_number" "$RESERVATIONS_FILE"; then
        guest_details=$(grep "^$room_number" "$RESERVATIONS_FILE")
        guest_name=$(echo "$guest_details" | cut -d'|' -f2)
        check_in_date=$(echo "$guest_details" | cut -d'|' -f3)
        check_out_date=$(echo "$guest_details" | cut -d'|' -f4)
        room_type=$(echo "$guest_details" | cut -d'|' -f5)

        check_in_timestamp=$(date -d "$check_in_date" +%s)
        check_out_timestamp=$(date -d "$check_out_date" +%s)
        diff=$((check_out_timestamp - check_in_timestamp))
        total_days=$(( (diff + 86399) / 86400 ))  # Rounding up to the next full day

        cost=0
        case $room_type in
            1)
                room="AC Single"
                charge_per_day=2000
                ;;
            2)
                room="Non-AC Single"
                charge_per_day=1000
                ;;
            3)
                room="AC Double"
                charge_per_day=3000
                ;;
            4)
                room="Non-AC Double"
                charge_per_day=1500
                ;;
            *)
                echo "Invalid room type"
                exit 1
                ;;
        esac

        cost=$((total_days * charge_per_day))

        echo "-----------------------------------------------------------------------------------"
        echo "Room Number: $room_number"
        echo "Guest Name: $guest_name"
        echo "Thank you for booking $room room(s) from $check_in_date to $check_out_date."
        echo "Total number of days: $total_days"
        echo "The total cost is $cost."
        echo "Thank you, visit again!"
        echo "------------------------------------------------------------------------------------"

        # Remove the reservation after billing
        remove_reservation "$room_number"
    else
        echo "Room number not found."
    fi
}

# Function to show the menu
show_menu() {
    echo "WELCOME TO HOTEL QUEENS"
    echo "1. Add reservation"
    echo "2. Remove reservation"
    echo "3. List reservations"
    echo "4. Bill printing"
    echo "5. Quit"
    read -p "Enter your choice: " choice
    echo $choice
}

# Main program loop
while true; do
    choice=$(show_menu)
    case $choice in
        1)
            read -p "Guest name: " guest_name
            check_in_date=$(date +"%Y-%m-%d %T")
            echo "Check-in date (YYYY-MM-DD HH:MM:SS): $check_in_date"
            read -p "Check-out date (YYYY-MM-DD HH:MM:SS): " check_out_date

            # Validate check-out date format
            if ! date -d "$check_out_date" >/dev/null 2>&1; then
                echo "Invalid date format. Please enter the date as YYYY-MM-DD HH:MM:SS."
                continue
            fi

            read -p "Please select your room type: 1. AC Single 2. Non-AC Single 3. AC Double 4. Non-AC Double " room_type
            read -p "Room number: " room_number

            if grep -q "^$room_number|" "$RESERVATIONS_FILE"; then
                echo "The room $room_number is already occupied."
            else
                echo "Room is successfully booked."
                echo "$room_number|$guest_name|$check_in_date|$check_out_date|$room_type|" >> "$RESERVATIONS_FILE"
            fi
            ;;
        2)
            read -p "Room number: " room_number
            remove_reservation "$room_number"
            ;;
        3)
            list_reservations
            ;;
        4)
            bill
            ;;
        5)
            echo "Thank you, visit again!"
            exit 0
            ;;
        *)
            echo "Invalid choice, please try again."
            ;;
    esac
done
