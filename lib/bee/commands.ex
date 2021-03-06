##
# Author:     Sterling Stanford-Jones
# Copyright:      Copyright (C) 2019
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
defmodule Bee.Commands do
  alias __MODULE__
  use Bitwise
  require Logger

  def rpcSend(bee, packetType, message \\ nil, payload \\ nil) do
    mseq = Map.get(bee, :sequence)
    new_sequence = mseq + 1
    new_bee = %{bee | :sequence => new_sequence}
    buffer = Bee.Packet.rpcToBuffer(new_sequence, packetType, message, payload)
    :gen_udp.send(new_bee.port, new_bee.remote_ip, new_bee.connection_port, buffer)
    # Should we try to resend dropped packets?
    new_bee
  end

  def sendControlUpdate(bee, %Imperium.Controller{xr: rx, yr: ry, yl: ly, xl: lx}) do
    payload = Bee.Packet.controllerToPayload(rx, ry, lx, ly)
    new_bee = Map.replace!(bee, :busy, true)
    rpcSend(new_bee, :ptData2, :msgSetStick, payload)
  end

  def sendTimeUpdate(bee) do
    payload = Bee.Packet.dateTimeToPayload()
    rpcSend(bee, :ptData1, :msgSetDateTime, payload)
  end

  def sendTakeoff(bee) do
    rpcSend(bee, :ptSet, :msgDoTakeoff)
  end

  def sendThrowTakeoff(bee) do
    rpcSend(bee, :ptGet, :msgDoThrowTakeoff, <<0x00>>)
  end

  def sendLand(bee) do
    rpcSend(bee, :ptSet, :msgDoLand, <<0x00>>)
  end

  def sendPalmLand(bee) do
    rpcSend(bee, :ptSet, :msgDoPalmLand, <<0x00>>)
  end

  # TakePicture requests the Tello to take a JPEG snapshot.
  # The process takes a little while to complete and the video may freeze
  # during photography.  Sometime the Tello does not honour the request.
  # The pictures are stored in the tello struct until saved by eg. SaveAllPics().
  def takePicture(bee) do
    rpcSend(bee, :ptSet, :msgDoTakePic)
  end

  def sendFileSize(bee) do
    rpcSend(bee, :ptData1)
  end

  def sendFileAckPiece(bee, done, fID, pieceNum) do
    payload =
      done
      |> join(fID)
      |> join(fID >>> 8)
      |> join(pieceNum)
      |> join(pieceNum >>> 8)
      |> join(pieceNum >>> 16)
      |> join(pieceNum >>> 24)

    rpcSend(bee, :ptData1, :msgFileData, payload)
  end

  def sendFileDone(bee, fID, size) do
    payload =
      fID
      |> join(fID >>> 8)
      |> join(size)
      |> join(size >>> 8)
      |> join(size >>> 16)
      |> join(size >>> 24)

    rpcSend(bee, :ptGet, :msgFileDone, payload)
  end

  # VideoDisconnect closes the connection to the video channel.
  def videoDisconnect() do
    # TODO Should we tell the Tello we are stopping video listening?
  end

  # GetVideoBitrate requests the current video Mbps from the Tello.
  def getVideoBitrate() do
    # newPacket(ptGet, msgQueryVideoBitrate, tello.ctrlSeq, 0)
    # rpcSend(bee, packet)
  end

  # SetVideoBitrate ask the Tello to use the specified bitrate (or auto) for video encoding.
  def setVideoBitrate(vbr) do
    # pkt = newPacket(ptSet, msgSetVideoBitrate, tello.ctrlSeq, 1)
    # pkt.payload[0] = byte(vbr)
    # rpcSend(bee, packet)
  end

  # GetVideoSpsPps asks the Tello to send SPS and PPS in video stream.
  # Calling this more often decreases video bandwidth, calling less often
  # results in video artifacts.  Every 0.5 to 2.0 seconds seems a reasonable range.
  def getVideoSpsPps() do
    # newPacket(ptData2, msgQueryVideoSPSPPS, 0, 0)
    # rpcSend(bee, packet)
  end

  # SetVideoNormal requests video format to be (native) ~4:3 ratio.
  def setVideoNormal() do
    # pkt = newPacket(ptSet, msgSwitchPicVideo, tello.ctrlSeq, 1)
    # pkt.payload[0] = vmNormal
    # rpcSend(bee, packet)
  end

  # SetVideoWide requests video format to be (cropped) 16:9 ratio.
  def setVideoWide() do
    # pkt = newPacket(ptSet, msgSwitchPicVideo, tello.ctrlSeq, 1)
    # pkt.payload[0] = vmWide
    # rpcSend(bee, packet)
  end

  # GetAttitude requests the current flight attitude data.
  # always seems to return 5 bytes 00 00 00 c8 41
  def getAttitude() do
    # newPacket(ptGet, msgQueryAttitude, tello.ctrlSeq, 0)
    # rpcSend(bee, packet)
  end

  # SetLowBatteryThreshold set the warning threshold to a percentage value (0-100).
  # N.B. It can take a few seconds for the Tello to change this value internally.
  def setLowBatteryThreshold(thr) do
    # packet = newPacket(:ptSet, :msgSetLowBattThresh, << thr >>)
    # rpcSend(bee, packet)
  end

  # GetLowBatteryThreshold requests the threshold from the Tello which is stored in
  # FlightData.LowBatteryThreshold as an integer percentage, i.e. from 0 to 100.
  def getLowBatteryThreshold() do
    # newPacket(ptGet, msgQueryLowBattThresh, tello.ctrlSeq, 0)
    # rpcSend(bee, packet)
  end

  # GetMaxHeight asks the Tello to send us its current maximum permitted height.
  def getMaxHeight() do
    # newPacket(ptGet, msgQueryHeightLimit, tello.ctrlSeq, 0)
    # rpcSend(bee, packet)
  end

  # GetSSID asks the Tello to send us its current Wifi AP ID.
  def getSSID() do
    # newPacket(ptGet, msgQuerySSID, tello.ctrlSeq, 0)
    # rpcSend(bee, packet)
  end

  # GetVersion asks the Tello to send us its Version string
  def getVersion() do
    # newPacket(ptGet, msgQueryVersion, tello.ctrlSeq, 0)
    # rpcSend(bee, packet)
  end

  def join(stream, append) do
    case append do
      nil ->
        <<stream::binary>>

      _ ->
        <<stream::binary, append::binary>>
    end
  end
end
