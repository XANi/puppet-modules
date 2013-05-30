class mpd::server (
    music_dir = '/var/lib/mpd/music',
    playlist_dir = '/var/lib/mpd/playlists',
    bind_to = '0.0.0.0',
    zeroconf = false,
)
{
    package { 'mpd':
        ensure => installed,
    }
}
