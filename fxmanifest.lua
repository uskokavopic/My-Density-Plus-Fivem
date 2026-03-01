fx_version 'cerulean'
game 'gta5'

name 'my_density_plus'
author 'Uskokavopic'
description 'Population density management (profiles + zones + crowd scaling + ymaps)'
version '1.1.0'

client_scripts {
    '@ox_lib/init.lua',
    'client.lua'
}

files {
    'config.lua',
    'stream/*.ymap'
}

-- If you stream ymaps as “car generator removers”, keep this:
data_file 'DLC_ITYP_REQUEST' 'stream/*.ymap'

lua54 'yes'
use_experimental_fxv2_oal 'yes'