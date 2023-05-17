import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "textField", "checkbox" ]
  static outlets = [ "checkbox_filter" ]

  clearForm() {
    this.textFieldTargets.forEach(input => input.value = "")
    this.checkboxTargets.forEach(input => input.checked = false)
    console.log(this.checkboxFilterOutlets)
    //    this.checkboxOutlets.forEach(type => type.updateCount())
    //this.dispatch("clearForm")

//    const event = new CustomEvent("clearForm");
//    window.dispatchEvent(event);
  }
}
