#!/bin/bash

# sudo yetkisi iste
echo "Lütfen sudo parolanızı girin:" | rofi -dmenu -password | sudo -S echo "Yetkilendirildi"

# LXC konteyner listesini al
output=$(sudo lxc-ls -f)

# Eğer konteyner yoksa bildirim göster ve çık
if [[ -z "$output" ]]; then
    notify-send "LXC Hata" "Hiçbir konteyner bulunamadı!"
    exit 1
fi

# İlk Rofi menüsünde konteyner listesini göster
while true; do
    # Yenileme satırını da ekle
    updated_output=$(echo -e "Yenile\n$(echo "$output")")

    # Konteyner listesini göster
    selection=$(echo "$updated_output" | rofi -dmenu -markup-rows -scroll-method 1 -p "Konteyner Seç" -wrap-mode 0)

    # ESC tuşuna basılırsa uygulamadan çık
    if [[ -z "$selection" ]]; then
        exit 1
    fi

    # Eğer "Yenile" seçilirse konteyner listesini yeniden al
    if [[ "$selection" == "Yenile" ]]; then
        output=$(sudo lxc-ls -f)
        continue
    fi

    # Seçimden sadece konteyner ismini al (ilk sütun)
    container_name=$(echo "$selection" | awk '{print $1}')

    # Seçilen konteynerin durumu
    state=$(echo "$selection" | awk '{print $2}')

    # Start / Stop seçeneklerini sun
    while true; do
        if [[ "$state" == "STOPPED" ]]; then
            action=$(echo -e "Start\nEsc - Geri" | rofi -dmenu -p "İşlem Seç")
        elif [[ "$state" == "RUNNING" ]]; then
            action=$(echo -e "Stop\nEsc - Geri" | rofi -dmenu -p "İşlem Seç")
        else
            notify-send "Hata" "Bilinmeyen durum: $state"
            exit 1
        fi

        # Eğer ESC tuşuna basılırsa, üst menüye dön
        if [[ -z "$action" || "$action" == "Esc - Geri" ]]; then
            break
        fi

        # Seçime göre işlemi gerçekleştir
        case "$action" in
            Start)
                sudo lxc-start -n "$container_name"
                notify-send "Konteyner Başlatıldı" "$container_name başarıyla başlatıldı!"
                # Konteyner listesini güncelle
                output=$(sudo lxc-ls -f)
                break
                ;;
            Stop)
                sudo lxc-stop -n "$container_name"
                notify-send "Konteyner Durduruldu" "$container_name başarıyla durduruldu!"
                # Konteyner listesini güncelle
                output=$(sudo lxc-ls -f)
                break
                ;;
            *)
                notify-send "Hata" "Geçersiz seçim yapıldı!"
                ;;
        esac
    done
done

