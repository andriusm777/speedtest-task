<template>
  <div class="container">
    <div class="speed-card-container">
      <div class="speed-card">
        <div class="speed-card-title">
          <span class="speed-card-title-text">Download</span>
        </div>
        <div class="speed-card-value">
          <template v-if="this.downloadResult !== ''">
            <span class="speed-card-value-text">{{this.downloadResult}}</span>
          </template>
          <template v-else>
            <span class="speed-card-value-text">0</span>
          </template>
        </div>
        <div class="speed-card-unit">
          <span class="speed-card-unit-text">Mbps</span>
        </div>
      </div>

      <div class="pre-speed-user-data">
        <div class="pre-speed-user-logo">
          <a-icon type="global" :style="{ fontSize: '21px'}"/>
        </div>
        <div class="pre-speed-user-data-info">
          <template v-if="hasSpeedtestStarted" >
            <span>{{userLocationData.country_name}}</span>
            <span>{{userLocationData.ip}}</span>
          </template>
          <template v-else>
            <span>Unknown</span>
          </template>
        </div>

      </div>

      <div class="speed-card">
        <div class="speed-card-title">
          <span class="speed-card-title-text">Upload</span>
        </div>
        <div class="speed-card-value">
          <template v-if="this.uploadResult !== ''">
            <span class="speed-card-value-text">{{this.uploadResult}}</span>
          </template>
          <template v-else>
            <span class="speed-card-value-text">0</span>
          </template>
        </div>
        <div class="speed-card-unit">
          <span class="speed-card-unit-text">Mbps</span>
        </div>
      </div>
    </div>
    <div class="speed-status">
      <span v-if="speedtestStatusMessage !== ''" class="speed-status-message">{{speedtestStatusMessage}}</span>
      <span v-else>Start speedtest</span>
    </div>
    <div class="speed-speedometer">
      <a-progress v-if="this.hasDownloadFinished === false"
        stroke-linecap="square"
        strokeColor="#108ee9"
        :percent="this.downloadPercent"
        :width="200"
        :showInfo="false"
        type="dashboard"
      />

      <a-progress v-if="this.hasDownloadFinished === true"
        stroke-linecap="square"
        strokeColor="#87d068"
        :percent="uploadPercentAdjust()"
        :width="200"
        :showInfo="false"
        type="dashboard"
      />
    </div>
    <template>
      <div class="speed-card-unit-text speed-speedometer-inside">
        <span v-if="this.downloadResult === '' && this.uploadResult === '' || this.hasDownloadFinished === true && this.hasUploadFinished === true">0 </span>
        <template v-if="this.hasDownloadStarted === true && this.hasDownloadFinished == false">
          <span>{{this.downloadResult}} </span>
        </template>
        <template v-if="this.hasUploadStarted == true && this.hasUploadFinished == false">
          <span>{{this.uploadResult}} </span>
        </template>
        Mbps
      </div>
    </template>

    <div class="speed-actions">
      <a-button :disabled="!isUserConnected" shape="round" size="large" type="primary" ghost @click="startSpeedtest">Start</a-button>

    </div>

    <div v-if="!isUserConnected" class="pre-speed-error">
      <a-icon type="exclamation-circle" :style="{ fontSize: '21px', color: '#ff3333'}"/>
      <span class="pre-speed-error-text">Connection cannot be established</span>
    </div>

  </div>
</template>

<script>

export default {
  data () {
    return {
      hasSpeedtestStarted: false,
      hasDownloadStarted: false,
      hasUploadStarted: false,
      isUserConnected: Boolean,
      userLocationData: Object,
      allServers: [],
      filteredServers: Array,
      speedtestStatusMessage: '',
      bestServer: '',
      downloadResult: '',
      downloadStatus: '',
      uploadResult: '',
      uploadStatus: '',
      downloadPercent: 0,
      uploadPercent: 0,
      hasDownloadFinished: false,
      hasUploadFinished: false
    }
  },
  timers: {
    getDownloadResults: { time: 900, autostart: false, immediate: true, repeat: true },
    getUploadResults: { time: 900, autostart: false, immediate: true, repeat: true }
  },
  methods: {
    startSpeedtest () {
      this.downloadResult = ''
      this.uploadResult = ''
      this.bestServer = ''
      this.downloadPercent = 0
      this.uploadPercent = 0
      this.hasDownloadStarted = false
      this.hasUploadStarted = false
      this.hasUploadFinished = false
      this.hasDownloadFinished = false
      this.hasSpeedtestStarted = true
      this.userConnectionStatus()
      this.getLocation()
      this.waitForAction(() => this.isUserConnected !== false && this.userLocationData !== null).then(() => {
        if (this.allServers.length === 0) {
          this.getServers()
        }
        this.waitForAction(() => this.allServers.length !== 0).then(() => {
          this.startServerOperations(this.filteredServersCountry)
        })
      })
    },
    uploadPercentAdjust () {
      if (this.downloadStatus === 'done' && this.uploadStatus === 'done') {
        // eslint-disable-next-line
        setTimeout(() => this.uploadPercent = 0, 800)
      }
      return this.uploadPercent
    },
    getLocation () {
      console.log('checking location')
      this.$rpc.call('speedtest-api', 'get_location_data').then((response) => {
        console.log('the response data is')
        console.log(response.data)
        console.log(JSON.parse(response.data))
        this.userLocationData = JSON.parse(response.data)
      })
    },
    userConnectionStatus () {
      const connectionTestServer = 'www.google.com'
      this.$rpc.call('speedtest-api', 'check_connection_status', { server: connectionTestServer }).then((response) => {
        console.log(response.connected)
        this.isUserConnected = response.connected
      })
      this.isUserConnected ? this.speedtestStatusMessage = 'Connected' : this.speedtestStatusMessage = 'Disconnected'
    },
    // If action is completed, a resolve callback is fired
    // otherwise we give 800ms for the action to complete
    waitForAction (isFunctonTruthy) {
      const pollingAction = (resolve) => {
        if (isFunctonTruthy()) {
          resolve()
        } else {
          setTimeout(() => pollingAction(resolve), 800)
        }
      }
      return new Promise(pollingAction)
    },
    getServers () {
      this.$rpc.call('speedtest-api', 'get_all_servers').then((response) => {
        console.log(JSON.parse(response.data))
        this.allServers = JSON.parse(response.data)
      })
    },
    startDownloadTest (server) {
      this.$rpc.call('speedtest-api', 'start_download', { server }).then((response) => {
        console.log(response.message)
        this.speedtestStatusMessage = response.message
        this.hasDownloadStarted = response.hasStarted
      })
    },
    startUploadTest (server) {
      this.$rpc.call('speedtest-api', 'start_upload', { server }).then((response) => {
        console.log(response.message)
        this.speedtestStatusMessage = response.message
        this.hasUploadStarted = response.hasStarted
      })
    },
    getUploadResults () {
      this.$rpc.call('speedtest-api', 'get_upload_results').then((response) => {
        console.log(response)
        if (response.data[0] === null) {
          // eslint-disable-next-line
          return
        } else if (response.data.length !== 0) {
          const responseData = response.data[0]
          const dataArray = responseData.split(',')
          console.log(dataArray)
          const uploadData = parseFloat(dataArray[1])
          const uploadPercent = parseInt(dataArray[2])
          this.uploadPercent = uploadPercent
          this.uploadResult = uploadData.toFixed(2)
          this.uploadStatus = dataArray[0]
          if (dataArray[0] === 'done') {
            this.speedtestStatusMessage = 'Upload test finished'
            this.$timer.stop('getUploadResults')
            this.hasUploadFinished = true
          } else if (dataArray[0] === 'processing') {
            this.speedtestStatusMessage = 'Upload being processed'
          }
        }
      })
    },
    getDownloadResults () {
      this.$rpc.call('speedtest-api', 'get_download_results').then((response) => {
        console.log(response)
        if (response.data[0] === null) {
          // eslint-disable-next-line
          return
        } else if (response.data.length !== 0) {
          const responseData = response.data[0]
          const dataArray = responseData.split(',')
          console.log(dataArray)
          const downloadData = parseFloat(dataArray[1])
          const downloadPercent = parseInt(dataArray[2])
          this.downloadPercent = downloadPercent
          this.downloadResult = downloadData.toFixed(2)
          this.downloadStatus = dataArray[0]
          if (this.downloadStatus === 'done') {
            this.speedtestStatusMessage = 'Download test finished'
            this.$timer.stop('getDownloadResults')
            this.hasDownloadFinished = true
            // setTimeout(this.startUploadTest(this.bestServer), 800)
          } else if (this.downloadStatus === 'processing') {
            this.speedtestStatusMessage = 'Download being processed'
          }
        }
      })
    },
    startServerOperations (servers) {
      this.$rpc.call('speedtest-api', 'find_servers', { servers }).then((response) => {
        this.speedtestStatusMessage = response.message
        this.findBestServer()

        this.waitForAction(() => this.bestServer !== '').then(() => {
          this.startDownloadTest(this.bestServer)
          this.waitForAction(() => this.hasDownloadStarted === true).then(() => {
            this.$timer.start('getDownloadResults')

            this.waitForAction(() => this.hasDownloadFinished === true).then(() => {
              this.startUploadTest(this.bestServer)
              this.waitForAction(() => this.hasUploadStarted === true).then(() => {
                this.$timer.start('getUploadResults')
              })
            })
          })
        })
      })
    },
    findBestServer () {
      this.$rpc.call('speedtest-api', 'init_best_server_search').then((response) => {
        console.log(response)
        if (response.message) {
          this.getBestServer()
        }
      })
    },
    getBestServer () {
      this.$rpc.call('speedtest-api', 'get_best_server').then((response) => {
        console.log(response)
        this.speedtestStatusMessage = response.message
        const data = JSON.parse(response.data)
        this.bestServer = data[0].server
        console.log(data[0])
      })
    }
  },
  computed: {
    filteredServersCountry () {
      return this.allServers.filter(provider => provider.country === this.userLocationData.country_name)
    }
  }
}

</script>

<style scoped>
  .meter {
    position:absolute;
    top:0;
    left:0;
    width:100%;
    height:100%;
    z-index:1;
  }

  .container {
    margin: 0 auto;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    row-gap: 20px;
  }

  .speed-card-container {
    display: flex;
    column-gap: 10px;
    align-items: center;
    justify-content: center;
  }

  .speed-card {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: space-evenly;
    width: 220px;
    height: 150px;
    box-shadow: rgba(0, 0, 0, 0.05) 0px 6px 24px 0px, rgba(0, 0, 0, 0.08) 0px 0px 0px 1px;
    border-radius: 8px;
  }

  .speed-card:hover {
    transition: all 0.3s ease-in-out;
    box-shadow: rgba(0, 0, 0, 0.16) 0px 10px 36px 0px, rgba(0, 0, 0, 0.06) 0px 0px 0px 1px;
  }

  .speed-card > div {
    margin-left: 10px;
  }

  .speed-card-title-text {
    font-size: 15px;
    text-transform: uppercase;
    font-weight: bold;
  }

  .speed-card-value-text {
    padding: 0;
    margin: 0;
    font-size: 45px;
    font-weight: lighter;
  }

  .speed-card-unit-text {
    font-weight: bold;
    color: lightslategrey;
  }

  /* SPEEDOMETER */
  .speed-speedometer {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .speed-speedometer-inside {
    margin-top: -50px;
  }

  /* ACTIONS */

  .speed-actions {
    display: flex;
    align-items: center;
    justify-content: space-between;
    column-gap: 50px;
    margin-top: 15px;
  }

  /* PRE SPEEDTEST START SECTION */

  .pre-speed-title {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  .pre-speed-user-data {
    margin-top: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    column-gap: 10px;
  }

  .pre-speed-user-logo {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .pre-speed-user-data-info {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: center;
  }

  .pre-speed-error {
    display: flex;
    justify-content: space-around;
    align-items: center;
    width: 250px;
  }

  .pre-speed-error-text {
    color: #ff3333;
    font-size: 14px;
  }

</style>
