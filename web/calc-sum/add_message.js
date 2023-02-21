//const sleep = (m) => new Promise(r => setTimeout(r, m))

/** @type {HTMLElement} */
let output = null
/** @type {(a: number, b: number) => void} */
let add_message_function

/**
 * @param {number} a
 * @param {number} b
 * @param {number} sum
 */
const log_add_message = (a, b, sum) => {
  if (output === null) {
    console.log("page load not complete: log_add_message")
    return
  }
  output.innerHTML += `${a} + ${b} = ${sum}<br />`
}

const importObject = {
  env: {
    log_add_message
  }
}

;(async () => {
  // await sleep(5000)
  const wasm = await WebAssembly.instantiateStreaming(fetch("add_message.wasm"), importObject)
  add_message_function = wasm.instance.exports.add_message

  const btn = document.getElementById("add_message_button")
  btn.style.display = "block"
})()

const onPageLoad = () => {
  //;(async () => {
  //await sleep(5000)
  output = document.getElementById("output")
  //})()
}

const onClickAddMessageButton = () => {
  const a = document.getElementById("a_val").value
  const b = document.getElementById("b_val").value
  add_message_function(a, b)
}
