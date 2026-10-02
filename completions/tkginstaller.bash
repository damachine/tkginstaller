_tkginstaller() {
  local cur prev
  local -r commands='linux linux-nvidia nvidia mesa wine proton config edit clean help dxvk vkd3d linux-tkg nvidia-all mesa-git wine-tkg proton-tkg updxvk upvkd3d l ln n m w p d c e h --help -h --clean'
  local -r config_commands='config edit c e'
  local -r config_packages='linux nvidia mesa wine proton dxvk vkd3d linux-tkg nvidia-all mesa-git wine-tkg proton-tkg updxvk upvkd3d l n m w p d v'

  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD - 1]}

  if ((COMP_CWORD == 1)); then
    mapfile -t COMPREPLY < <(compgen -W "${commands}" -- "${cur}")
    return
  fi

  if ((COMP_CWORD != 2)); then
    return
  fi

  case "${prev}" in
    config | edit | c | e)
      mapfile -t COMPREPLY < <(compgen -W "${config_packages}" -- "${cur}")
      ;;
    linux | nvidia | mesa | wine | proton | dxvk | vkd3d | \
      linux-tkg | nvidia-all | mesa-git | wine-tkg | proton-tkg | updxvk | upvkd3d | \
      l | n | m | w | p | d | v | g)
      mapfile -t COMPREPLY < <(compgen -W "${config_commands}" -- "${cur}")
      ;;
  esac
}

complete -F _tkginstaller tkginstaller
