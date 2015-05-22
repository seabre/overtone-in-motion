(ns overtone-in-motion.motion
  (:use overtone.live
        overtone.synth.stringed
        overtone.inst.sampled-piano)
  (:require [aleph.udp :as udp]
            [manifold.stream :as st]
            [byte-streams :as bs]
            [clojure.string :as str]))


(def piano-vol 0.5)
(def guitar-vol 12.0)

(def server (osc-server 8675 "gridstrument"))
;; (osc-close server)

(gen-stringed-synth pektara 1 false) ;; persistent ektara

(def pitch-bend-range 10) ;; keep in sync with GridStrument

;; six fingers should be good enough.
(def eks [(pektara) (pektara) (pektara) (pektara) (pektara) (pektara)])
(def eks-notes [(atom 0) (atom 0) (atom 0) (atom 0) (atom 0) (atom 0)])

;; adjust the eks sound to whatever suits you
(dorun (map
        #(ctl %
              :pre-amp guitar-vol
              :lp-freq 3000 :lp-rq 0.25
              :rvb-mix 0.3 :rvb-room 0.7 :rvb-damp 0.4)
        eks))

;; translate GridStrument into awesomeness!
(defn grid-note
  [channel note value]
  ;;(println "note" channel note value)
  (if (= value 0)
    (do
      (reset! (nth eks-notes channel) 0)
      (ctl (nth eks channel) :gate 0))
    (do
      (reset! (nth eks-notes channel) note)
      (ctl (nth eks channel) :note note :gate 1 :amp (/ value 127.0)))))

(defn grid-cc
  [channel note value]
  (let [norm-value (/ value 127.0)
        norm-value (* norm-value 0.9)] ;; don't allow 1.0 distortion
    ;;(println "cc" channel note value norm-value)
    (ctl (nth eks channel) :distort norm-value)))

(defn grid-pitch-bend
  [channel value]
  (let [norm-value (/ (- value 8192.0) 8192.0)
        offset (* norm-value pitch-bend-range)
        note (+ @(nth eks-notes channel) offset)]
    ;;(println "pitch" channel value norm-value)
    (ctl (nth eks channel) :note note)))

(defn grid-pressure
  [channel value]
  (let [norm-value (/ value 127.0)]
    ;;(println "pressure" channel value norm-value)
    (ctl (nth eks channel) :amp (/ value 127.0))))

(defn grid-unknown
  [msg]
  (println "???" msg))

(defn listen [msg]
  (let [path        (:path msg)
        value       (first (:args msg))
        is-note     (re-matches #"/vkb_midi/(.*)/note/(.*)" (:path msg))
        is-cc       (re-matches #"/vkb_midi/(.*)/cc/(.*)" (:path msg))
        is-pitch    (re-matches #"/vkb_midi/(.*)/pitch" (:path msg))
        is-pressure (re-matches #"/vkb_midi/(.*)/channelpressure" (:path msg))]
    (if is-note (grid-note (Integer/parseInt (nth is-note 1))
                           (Integer/parseInt (nth is-note 2)) value)
        (if is-cc (grid-cc (Integer/parseInt (nth is-cc 1))
                           (Integer/parseInt (nth is-cc 2)) value)
            (if is-pitch (grid-pitch-bend (Integer/parseInt (nth is-pitch 1)) value)
                (if is-pressure (grid-pressure (Integer/parseInt (nth is-pressure 1)) value)
                    (grid-unknown msg)))))))
(osc-listen server listen :gridstrument)




(def udp-socket @(udp/socket {:port 10001}))

(sampled-piano (note :d4))

(def notes
  (vec (map vec [(scale :e4 :pentatonic)
                 (scale :e4 :pentatonic)
                 (scale :e4 :pentatonic)
                 (scale :e4 :pentatonic)
                 (scale :e4 :pentatonic)
                 (scale :e4 :pentatonic)
                 (scale :e4 :pentatonic)
                 (scale :e4 :pentatonic)])))

(defn parse-int [s]
  (Integer/parseInt (re-find #"\A-?\d+" s)))

(defn parse-msg [m]
  (map parse-int (str/split m #",")))

(defn play-notes [v]
  (sampled-piano (get-in notes v) piano-vol))

(defn unpack-play [d]
  (play-notes (parse-msg (bs/to-string (:message d)))))

(st/consume #(unpack-play %) udp-socket)
