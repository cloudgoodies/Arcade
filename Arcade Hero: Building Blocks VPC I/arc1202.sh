echo -e "\e[34mCreating Google Cloud network: \e[1;32mstaging\e[0m"
gcloud compute networks create staging --subnet-mode=auto
echo -e "\e[34mNetwork creation completed.\e[0m"
