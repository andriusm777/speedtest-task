<template>
  <div class="container">
    <div v-if="hasSpeedtestStarted">
      <a-row type="flex" justify="space-around" class="test" align="middle">
        <a-col :span="12">
          <div class="speed-card-container">
            <div class="speed-card">
              <div class="speed-card-title">
                <span class="speed-card-title-text">Download</span>
              </div>
              <div class="speed-card-value">
                <span class="speed-card-value-text">565</span>
              </div>
              <div class="speed-card-unit">
                <span class="speed-card-unit-text">Mbps</span>
              </div>
            </div>

            <div class="speed-card">
              <div class="speed-card-title">
                <span class="speed-card-title-text">Upload</span>
              </div>
              <div class="speed-card-value">
                <span class="speed-card-value-text">400</span>
              </div>
              <div class="speed-card-unit">
                <span class="speed-card-unit-text">Mbps</span>
              </div>
            </div>

            <div class="speed-card">
              <div class="speed-card-title">
                <span class="speed-card-title-text">Ping</span>
              </div>
              <div class="speed-card-value">
                <span class="speed-card-value-text">20</span>
              </div>
              <div class="speed-card-unit">
                <span class="speed-card-unit-text">ms</span>
              </div>
            </div>
          </div>

        </a-col>

        <a-col :span="12">
          <div justify="center" align="middle">
            <a-progress type="circle" :percent="100" :width="200"/>
          </div>
        </a-col>
      </a-row>

      <!-- <a-row type="flex" justify="space-around" class="test" align="middle">
        <a-col :span="12">
          <div justify="center" align="middle">
            <a-button type="primary">
              Start
            </a-button>
          </div>
        </a-col>
      </a-row> -->
    </div>
    <div v-else class="pre-speed-container">
        <div class="pre-speed-title">
          <span class="pre-speed-title-main">Speedtest</span>
          <span v-if="isUserConnected" class="pre-speed-title-desc">To begin the speedtest please click the start button</span>
          <span v-else class="pre-speed-title-desc">Make sure you have a stable connection and then click the start button</span>
        </div>

        <a-button :disabled="!isUserConnected" shape="round" size="large" @click="startSpeedtest">Start</a-button>
        <div v-if="isUserConnected" class="pre-speed-user-data">
          <div class="pre-speed-user-logo">
            <a-icon type="global" :style="{ fontSize: '21px'}"/>
          </div>
          <div class="pre-speed-user-data-info">
            <span>{{userLocationData.org}}</span>
            <span>{{userLocationData.ip}}</span>
          </div>
        </div>
        <div v-if="!isUserConnected" class="pre-speed-error">
          <a-icon type="exclamation-circle" :style="{ fontSize: '21px', color: '#ff3333'}"/>
          <span class="pre-speed-error-text">Connection cannot be established</span>
        </div>
    </div>

  </div>
</template>

<script>

export default {
  data () {
    return {
      page: 'speedtest',
      hasSpeedtestStarted: false,
      isUserConnected: Boolean,
      userLocationData: Object
    }
  },
  methods: {
    startSpeedtest () {
      if (this.isUserConnected) {
        this.hasSpeedtestStarted = true
      }
    },
    getLocation () {
      this.$rpc.call('speedtest-api', 'getLocation', { }).then((response) => {
        console.log('the response data is')
        console.log(response.data)
        // const joinedStrings = response.data.join('')
        // console.log(joinedStrings)
        console.log(JSON.parse(response.data))
        this.userLocationData = JSON.parse(response.data)
        // console.log(JSON.parse(joinedStrings))
      })
    },
    userConnectionStatus () {
      const connectionTestServer = 'www.google.com'
      this.$rpc.call('speedtest-api', 'connectionStatus', { server: connectionTestServer }).then((response) => {
        console.log(response.connected)
        this.isUserConnected = response.connected
      })
    }
  },
  created () {
    this.getLocation()
    this.userConnectionStatus()
  }
}

</script>

<style scoped>
  .container {
    margin: 0 auto;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-content: center;
    justify-content: center;
  }

  .speed-card-container {
    display: flex;
    flex-direction: column;
    row-gap: 10px;
    align-items: center;
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

  /* PRE SPEEDTEST START SECTION */

  .pre-speed-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    row-gap: 15px;
  }

  .pre-speed-title {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  .pre-speed-title-main {
    font-size: 25px;
    font-weight: bold;
    margin-bottom: 5px;
  }

  .pre-speed-title-desc {
    margin-bottom: 10px;
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
