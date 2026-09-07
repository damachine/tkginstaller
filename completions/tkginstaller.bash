_tkginstaller() {
  local cur prev
  local -r commands='linux linux-nvidia nvidia mesa wine proton dxvk-tools dxvk amdgpu amdvlk gamescope glibc config edit clean help vkd3d linux-tkg nvidia-all mesa-git amdvlk-opt wine-tkg proton-tkg updxvk upvkd3d l ln n m w p d ag av g ge c e h --help -h --clean'
  local -r config_commands='config edit c e'
  local -r config_packages='linux nvidia mesa wine proton dxvk vkd3d amdgpu amdvlk gamescope linux-tkg nvidia-all mesa-git amdvlk-opt wine-tkg proton-tkg updxvk upvkd3d l n m w p d v ag av g'

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
    linux | nvidia | mesa | wine | proton | dxvk | vkd3d | amdgpu | amdvlk | gamescope | \
      linux-tkg | nvidia-all | mesa-git | amdvlk-opt | wine-tkg | proton-tkg | updxvk | upvkd3d | \
      l | n | m | w | p | d | v | ag | av | g)
      mapfile -t COMPREPLY < <(compgen -W "${config_commands}" -- "${cur}")
      ;;
  esac
}

complete -F _tkginstaller tkginstaller
